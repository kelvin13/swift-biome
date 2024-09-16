import Biome
import Multiparts
import NIO
import NIOHTTP1
import URI

protocol ExpressibleByHTTPRequest 
{
    init?(source:SocketAddress?, head:HTTPRequestHead)
    init?(source:SocketAddress?, head:HTTPRequestHead, body:[ByteBuffer], end:HTTPHeaders?)
}
extension ExpressibleByHTTPRequest 
{
    init?(source _:SocketAddress?, head _:HTTPRequestHead)
    {
        return nil 
    }
    init?(source:SocketAddress?, head:HTTPRequestHead, body _:[ByteBuffer], end _:HTTPHeaders?)
    {
        return nil 
    }
}

extension Service.Request:ExpressibleByHTTPRequest
{
    init?(source _:SocketAddress?, head:HTTPRequestHead)
    {
        guard let uri:URI = try? .init(absolute: head.uri)
        else 
        {
            return nil 
        }
        switch head.method
        {
        case .GET:
            self.init(.get, uri: uri)
        default:
            return nil
        }
    }
    init?(source _:SocketAddress?, head:HTTPRequestHead, body:[ByteBuffer], end _:HTTPHeaders?)
    {
        guard let uri:URI = try? .init(absolute: head.uri)
        else 
        {
            return nil 
        }
        switch head.method
        {
        case .POST:
            guard   let content:String = head.headers.contentType,
                    let content:MediaType = try? .init(parsing: content)
            else
            {
                return nil
            }

            let message:[UInt8] = .init(body.lazy.map(\.readableBytesView).joined())

            guard   let multipart:Multipart = try? .init(splitting: message, type: content),
                    let form:[Multipart.FormItem] = try? multipart.form()
            else
            {
                return nil
            }

            self.init(.post(form), uri: uri)

        default:
            return nil
        }
    }
}