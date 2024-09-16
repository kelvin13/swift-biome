#if canImport(NIOSSL)
import NIOSSL
#endif
enum Scheme:Sendable
{
    struct HTTP:Sendable
    {
        let port:Int
    }

    case http(HTTP)

    #if canImport(NIOSSL)
    case https(HTTPS)
    #endif
}
extension Scheme:CustomStringConvertible
{
    var description:String
    {
        switch self
        {
        case .http:     return "http"
        #if canImport(NIOSSL)
        case .https:    return "https"
        #endif
        }
    }
    var port:Int
    {
        switch self
        {
        case .http(let http):   return http.port
        #if canImport(NIOSSL)
        case .https(let https): return https.port
        #endif
        }
    }
}


#if canImport(NIOSSL)
extension Scheme
{
    struct HTTPS:Sendable
    {
        let securityContext:NIOSSLContext
        let http:HTTP
        let port:Int
    }
}
extension Scheme.HTTPS
{    
    init(certificate:String, privateKey:String, http:Scheme.HTTP, port:Int) throws
    {
        self.http = http
        self.port = port
        self.securityContext = try .init(configuration: .makeServerConfiguration(
            certificateChain: try NIOSSLCertificate.fromPEMFile(certificate)
                .map(NIOSSLCertificateSource.certificate(_:)),
            privateKey: .file(privateKey)))
    }
}
#endif