import Multiparts
import URI
import WebSemantics

extension Service:WebService
{
    @frozen public
    struct Request:Sendable 
    {
        @frozen public
        enum Method:Sendable
        {
            case get
            case post([Multipart.FormItem])
        }

        public
        let uri:URI 
        public
        let method:Method

        @inlinable public
        init(_ method:Method, uri:URI)
        {
            self.method = method
            self.uri = uri
        }
    }

    public
    func serve(_ request:Request) async throws -> WebResponse
    {
        switch request.method
        {
        case .get:
            return self.state.get(request.uri)
        
        case .post(let form):
            for item:Multipart.FormItem in form
            {
                print(item)
            }
            return .init(uri: request.uri.description, location: .none,
                payload: .init("unimplemented."))
        }
    }
}