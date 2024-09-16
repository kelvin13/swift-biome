// import SystemExtras
// import WebSemantics
// import Resources
// import HTML
// import NIO
// import NIOHTTP1
// import URI

// actor Preview
// {
//     struct Request:ExpressibleByPartialHTTPRequest, Sendable 
//     {
//         let uri:URI 
        
//         init?(source _:SocketAddress?, head:HTTPRequestHead)
//         {
//             if let uri:URI = try? .init(absolute: head.uri)
//             {
//                 self.uri = uri
//             }
//             else 
//             {
//                 return nil 
//             }
//         }
//     }
    
//     private 
//     var ecosystem:Ecosystem
    
//     init(projects:[FilePath], resources:FilePath, swift:MaskedVersion?) async throws 
//     {
//         self.ecosystem = .init()
        
//         try self.ecosystem.loadToolchains(from: resources.appending("swift"), 
//             matching: swift)
//         try self.ecosystem.loadProjects(from: projects)
        
//         try self.loadResources(from: resources)
        
//         self.ecosystem.move(.init(
//                 hashing: try resources.appending(["css", "biome.css"]).read(), 
//                 type: .utf8(encoded: .css)),
//             to: ["biome.css"])
//         self.ecosystem.move(.init(
//                 hashing: try resources.appending(["js", "main.js"]).read(), 
//                 type: .utf8(encoded: .javascript)),
//             to: ["search.js"])
//     }
    
//     private  
//     func loadResources(from directory:FilePath) throws 
//     {
//         try Task.checkCancellation()
        
//         let fonts:[(external:String, internal:String)] = 
//         [
//             ("text-45", "Literata-Regular"),
//             ("text-47", "Literata-RegularItalic"),
//             ("text-65", "Literata-SemiBold"),
//             ("text-67", "Literata-SemiBoldItalic"),
//         ]
//         try self.loadFonts(fonts, .ttf, .woff2, 
//             from: directory.appending(["fonts", "Literata"]))
//     }
//     private  
//     func loadFonts(_ fonts:[(external:String, internal:String)], _ types:MIME..., 
//         from directory:FilePath) throws 
//     {
//         for name:(external:String, internal:String) in fonts 
//         {
//             for type:MIME in types 
//             {
//                 let path:FilePath = 
//                     directory.appending("\(name.internal).\(type.extension)")
//                 self.ecosystem.move(.init(hashing: try path.read(), type: type), 
//                     to: ["\(name.external).\(type.extension)"])
//             }
//         }
//     }
// }

// extension Preview 
// {
//     func serve(_ requests:AsyncStream<Request.Enqueued>) async 
//     {
//         for await (request, promise):Request.Enqueued in requests 
//         {
//             promise.succeed(self.ecosystem[request.uri])
//         }
//     }
// }
