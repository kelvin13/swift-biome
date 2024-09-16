import NIO
import NIOHTTP1

final 
class Redirector:ChannelInboundHandler
{
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private 
    let target:String
    
    init(target:String) 
    {
        self.target = target
    }
    
    func channelRead(context:ChannelHandlerContext, data:NIOAny) 
    {
        guard case .head(let request) = self.unwrapInboundIn(data) 
        else 
        {
            return 
        }
        let head:HTTPResponseHead = .init(version: .http1_1, 
            status: .permanentRedirect, 
            headers: 
            [
                "location" : "https://\(self.target)\(request.uri)"
            ])
        context.write(self.wrapOutboundOut(HTTPServerResponsePart.head(head)), 
            promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil)), 
            promise: nil)
    }
    func channelReadComplete(context:ChannelHandlerContext) 
    {
        context.flush()
    }
    func userInboundEventTriggered(context:ChannelHandlerContext, event:Any) 
    {
        if  let event:ChannelEvent  = event as? ChannelEvent, 
            case .inputClosed       = event 
        {
            context.close(promise: nil)
        }
        else 
        {
            context.fireUserInboundEventTriggered(event)
        }
    }
}