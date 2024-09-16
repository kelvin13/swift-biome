import MIME
import NIO
#if canImport(NIOSSL)
import NIOSSL
#endif
import NIOHTTP1
import SHA2
import WebSemantics

extension HTTPHeaders 
{
    var hash:SHA256? 
    {
        self["if-none-match"].first.flatMap(SHA256.init(etag:))
    }
    var contentType:String? 
    {
        self["content-type"].first
    }
}

final
class Listener<Service>:ChannelInboundHandler, RemovableChannelHandler
    where Service:WebService, Service.Request:ExpressibleByHTTPRequest
{
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private 
    var request:(head:HTTPRequestHead, stream:[ByteBuffer])?,
        responding:Bool, 
        receiving:Bool
    private 
    let service:Service,
        source:SocketAddress?,
        scheme:String, 
        host:Host

    init(service:Service, 
        source:SocketAddress?, 
        scheme:String,
        host:Host) 
    {
        self.request    = nil 
        self.responding = false 
        self.receiving  = false
        self.service    = service 
        self.source     = source
        self.scheme     = scheme
        self.host       = host
    }
    func channelRead(context:ChannelHandlerContext, data:NIOAny) 
    {
        switch self.unwrapInboundIn(data) 
        {
        case .head(let head):
            self.receiving = head.isKeepAlive
            if  let request:Service.Request = .init(source: self.source, head: head)
            {
                self.conduct(request: _move request, context: context, hash: head.headers.hash)
                self.request = nil
            }
            else 
            {
                self.request = (head, [])
            }
            
        case .body(let buffer):
            if case (let head, var body)? = self.request 
            {
                self.request = nil 
                body.append(buffer)
                self.request = (head, body)
            }
        
        case .end(let end):
            guard case let (head, body)? = self.request 
            else 
            {
                // already responded
                break 
            }
            self.request = nil
            if  let request:Service.Request = .init(source: self.source, 
                    head: head, 
                    body: body, 
                    end: end)
            {
                self.conduct(request: _move request, context: context, hash: head.headers.hash)
            } 
            else 
            {
                let headers:HTTPHeaders = self.createHeaders()
                let response:HTTPResponseHead = .init(version: .http1_1, 
                    status: .badRequest, 
                    headers: headers)
                self.respond(head: response, context: context)
            }
        }
    }
    
    func channelReadComplete(context:ChannelHandlerContext) 
    {
        context.flush()
    }
    
    func userInboundEventTriggered(context:ChannelHandlerContext, event:Any) 
    {
        guard case .inputClosed? = event as? ChannelEvent
        else 
        {
            context.fireUserInboundEventTriggered(event)
            return 
        }
        self.receiving = false 
        guard self.responding 
        else 
        {
            context.close(promise: nil)
            return 
        }
    }
}
extension Listener
{
    private 
    func conduct(request:__owned Service.Request, context:ChannelHandlerContext, hash:SHA256?) 
    {
        let promise:EventLoopPromise<WebResponse> = 
            context.eventLoop.makePromise(of: WebResponse.self)
        
        promise.futureResult.whenComplete 
        {
            switch $0 
            {
            case .failure(let error): 
                let error:WebResponse = .init(uri: "/", location: .error, 
                    payload: .init("\(error)"))
                self.respond(with: error, context: context)
            
            case .success(let response):
                self.respond(with: response, ifNoneMatch: hash, context: context) 
            }
        }
        promise.completeWithTask
        {
            try await self.service.serve(request)
        }
    }
    
    private 
    func url(_ uri:String) -> String 
    {
        "\(self.scheme)://\(self.host.domain)\(uri)"
    }
    private 
    func createHeaders(canonical:String? = nil) -> HTTPHeaders 
    {
        if let canonical:String = canonical 
        {
            return ["host": self.host.domain, "link": "<\(self.url(canonical))>; rel=\"canonical\""]
        }
        else 
        {
            return ["host": self.host.domain]
        }
    }
    private 
    func createResponseHead(
        location uri:String, 
        canonical:String?, 
        status:HTTPResponseStatus) 
        -> HTTPResponseHead 
    {
        var headers:HTTPHeaders = self.createHeaders(canonical: canonical)
            headers.add(name: "location", value: self.url(uri))
        return .init(version: .http1_1, status: status, headers: headers)
    }
    private 
    func createResponse(containing payload:WebResponse.Payload, 
        allocator:ByteBufferAllocator,
        canonical:String? = nil, 
        status:HTTPResponseStatus)
        -> (head:HTTPResponseHead, body:IOData?) 
    {
        var headers:HTTPHeaders = self.createHeaders(canonical: canonical)
        let content:(length:Int, type:MIME), 
            buffer:ByteBuffer?
        switch payload.content
        {
        case .text(let string, type: let type):
            content.length = string.utf8.count
            content.type = .utf8(encoded: type)
            buffer = status == .notModified ? nil : allocator.buffer(string: string)
        case .bytes(let bytes,  type: let type):
            content.length = bytes.count
            content.type = type
            buffer = status == .notModified ? nil : allocator.buffer(bytes: bytes)
        }
        headers.add(name: "content-length", value: content.length.description)
        headers.add(name: "content-type",   value: content.type.description)
        if let hash:SHA256 = payload.hash
        {
            headers.add(name: "etag",       value: hash.etag)
        }
        let head:HTTPResponseHead = .init(version: .http1_1, status: status, 
            headers: headers)
        return (head, buffer.map(IOData.byteBuffer(_:)))
    }
    private 
    func respond(with response:WebResponse, 
        ifNoneMatch hash:SHA256? = nil,
        context:ChannelHandlerContext) 
    {
        let head:HTTPResponseHead, 
            body:IOData?
        switch response.redirection 
        {
        case .temporary:
            head = self.createResponseHead(location: response.uri, 
                canonical: response.canonical,
                status: .temporaryRedirect)
            body = nil 

        case .permanent:
            head = self.createResponseHead(location: response.uri, 
                canonical: response.canonical, 
                status: .permanentRedirect)
            body = nil
        
        case .none(let resource):
            switch response.location 
            {
            case .error:
                (head, body) = self.createResponse(containing: resource, 
                    allocator: context.channel.allocator,
                    status: .internalServerError)
            
            case .none:
                (head, body) = self.createResponse(containing: resource, 
                    allocator: context.channel.allocator,
                    status: .notFound)
            
            case .one(let canonical):
                let status:HTTPResponseStatus = 
                    resource.hash ?= hash ? .notModified : .ok
                (head, body) = self.createResponse(containing: resource, 
                    allocator: context.channel.allocator,
                    canonical: canonical, 
                    status: status)
            
            case .many:
                (head, body) = self.createResponse(containing: resource, 
                    allocator: context.channel.allocator,
                    status: .multipleChoices)
            }
        }
        self.respond(head: head, body: body, context: context)
    }
    private 
    func respond(head:HTTPResponseHead, body:IOData? = nil, 
        context:ChannelHandlerContext)
    {
        self.responding = true 
        
        let sent:EventLoopPromise<Void> = context.eventLoop.makePromise(of: Void.self)
            sent.futureResult.whenComplete 
        {
            (_:Result<Void, Error>) in 
            self.responding = false 
            if !self.receiving 
            {
                context.channel.close(promise: nil)
            }
        }
        context.write(self.wrapOutboundOut(HTTPServerResponsePart.head(head)), 
            promise: nil)
        if let body:IOData 
        {
            context.write(self.wrapOutboundOut(HTTPServerResponsePart.body(body)), 
                promise: nil)
        }
        context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)), 
            promise: sent)
    }
}