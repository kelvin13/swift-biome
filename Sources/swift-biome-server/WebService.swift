import NIO
import NIOHTTP1
#if canImport(NIOSSL)
import NIOSSL
#endif
import WebSemantics

extension WebService where Request:ExpressibleByHTTPRequest
{
    private static
    func redirect(on group:MultiThreadedEventLoopGroup, 
        scheme:Scheme.HTTPS, 
        host:Host) async throws -> any Channel
    {
        let bootstrap:ServerBootstrap = .init(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer 
        { 
            (channel:any Channel) -> EventLoopFuture<Void> in

            channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                .flatMap 
            {
                channel.pipeline.addHandler(Redirector.init(target: host.domain))
            }
        }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead,          value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        
        return try await bootstrap.bind(host: host.name, port: scheme.port).get()
    }

    private
    func listen(on group:MultiThreadedEventLoopGroup, 
        scheme:Scheme, 
        host:Host) async throws -> any Channel
    {
        let bootstrap:ServerBootstrap = .init(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer 
        { 
            (channel:any Channel) -> EventLoopFuture<Void> in
            
            switch scheme
            {
            #if canImport(NIOSSL)
            case .https(let https):
                let tls:NIOSSLServerHandler = .init(context: https.securityContext)
                return  channel.pipeline.addHandler(tls).flatMap 
                {
                        channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                        .flatMap 
                    {
                        let endpoint:Listener = .init(service: self, 
                            source: channel.remoteAddress, 
                            scheme: scheme.description,
                            host: host)
                        return channel.pipeline.addHandler(endpoint)
                    }
                }
            #endif
            case .http(_):
                return channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                    .flatMap 
                {
                    let endpoint:Listener = .init(service: self, 
                        source: channel.remoteAddress, 
                        scheme: scheme.description,
                        host: host)
                    return channel.pipeline.addHandler(endpoint)
                }
            }
        }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead,          value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        
        return try await bootstrap.bind(host: host.name, port: scheme.port).get()
    }
}
extension WebService where Request:ExpressibleByHTTPRequest
{
    func run(on group:MultiThreadedEventLoopGroup, scheme:Scheme, host:Host) async throws
    {
        let channels:[any Channel] = try await withThrowingTaskGroup(of: (any Channel).self)
        {
            (tasks:inout ThrowingTaskGroup<any Channel, Error>) in 
            
            tasks.addTask
            {
                try await self.listen(on: group, scheme: scheme, host: host)
            }
            #if canImport(NIOSSL)
            // set up http -> https redirection
            if case .https(let https) = scheme
            {
                tasks.addTask
                {
                    try await Self.redirect(on: group, scheme: https, host: host)
                }
            }
            #endif
            
            var channels:[any Channel] = []
            for try await channel:any Channel in tasks
            {
                let address:SocketAddress? = channel.localAddress 
                print("opened channel on \(address?.description ?? "<unavailable>")")
                channels.append(channel)
            }
            return channels
        }
        
        await withTaskGroup(of: Void.self)
        {
            (tasks:inout TaskGroup<Void>) in 
            
            for channel:Channel in channels 
            {
                tasks.addTask 
                {
                    // must capture this before the channel closes, since 
                    // the local address will be cleared
                    let address:SocketAddress? = channel.localAddress 
                    do 
                    {
                        try await channel.closeFuture.get()
                    }
                    catch let error 
                    {
                        print(error)
                    }
                    print("closed channel \(address?.description ?? "<unavailable>")")
                }
            }
            
            await tasks.next()
            
            for channel:Channel in channels 
            {
                tasks.addTask 
                {
                    do 
                    {
                        try await channel.pipeline.close(mode: .all)
                    }
                    catch let error 
                    {
                        print(error)
                    }
                }
            }
        }
    }
}