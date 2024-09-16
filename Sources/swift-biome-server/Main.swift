import ArgumentParser
import Backtrace
import BiomeDatabase
import Biome
import HTML
import NIO

import MongoDB

@main 
struct Main:AsyncParsableCommand 
{
    static 
    var configuration:CommandConfiguration = .init(abstract: "preview swift-biome documentation")
        
    @Option(name: [.customShort("p"), .customLong("port")], 
        help: "port number to listen on")
    var port:Int = 8080
    @Option(name: [.customShort("h"), .customLong("host")], 
        help: "private host name to listen on")
    var host:String = "0.0.0.0" 
    @Option(name: [.customShort("d"), .customLong("domain")], 
        help: "public host name")
    var domain:String = "127.0.0.1" 

    @Option(name: [.customShort("m"), .customLong("mongo")], 
        help: "mongodb host")
    var mongo:String = "mongodb" 

    // @Option(name: [.customLong("swift")], 
    //     help: "swift standard library version")
    // var swift:String = "*"
    
    // @Option(name: [.customLong("resources")], 
    //     help: "path to a copy of the 'swift-biome-resources' repository")
    // var resources:String = "resources"
    
    // @Argument(help: "path(s) to project repositories")
    // var projects:[String] 
    
    static 
    func main() async 
    {
        do 
        {
            let command:Self = try Self.parseAsRoot() as! Self
            try await command.run()
        } 
        catch 
        {
            exit(withError: error)
        }
    }
    
    func run() async throws 
    {
        Backtrace.install()
        
        let group:MultiThreadedEventLoopGroup = .init(numberOfThreads: 2)
        let scheme:Scheme = .http(.init(port: self.port))
        let host:Host = .init(domain: self.domain, name: self.host)

        let logo:HTML.Element<Never> = .ol(.li(.a(
                .init(escaped: "swift"), 
                .i(.init(escaped: "init"),
                .init(escaped: " (preview)")), 
            attributes: [.class("logo"), .href("/")])))
        
        
        // let service:Service = .init(database: .init(),
        //     logo: logo.node.rendered(as: [UInt8].self))

        // while true 
        // {
        //     do 
        //     {
        //         try await service.run(on: group, scheme: scheme, host: host)
        //     }
        //     catch let error 
        //     {
        //         print(error)
        //     }
        // }
    }
}
