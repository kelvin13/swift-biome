import JSON 
import WebResponse
import URI

struct Cache 
{
    let sitemap:WebResponse.Payload
    let search:WebResponse.Payload 
}

extension Service 
{
    func generateSearchIndex(for package:Package) -> WebResponse.Payload
    {
        fatalError("unimplemented")
        // let current:Tree.Pinned = self[package].pinned()
        // let modules:[JSON] = current.package.modules.all.map 
        // {
        //     var types:[JSON] = []
        //     for colony:Module.Colony in $0.symbols 
        //     {
        //         for offset:Symbol.Offset in colony.range 
        //         {
        //             let index:Symbol.Index = .init($0.index, offset: offset)
                    
        //             let symbol:Symbol = current.package[local: index]
        //             switch symbol.community
        //             {
        //             case .protocol, .typealias, .concretetype(_), .global(_):
        //                 break 
        //             case .associatedtype, .callable(_): 
        //                 continue
        //             }
        //             guard current.package.contains(index, at: current.version)
        //             else 
        //             {
        //                 continue 
        //             }
                    
        //             let declaration:Declaration<Symbol.Index> = current.declaration(index)
        //             let uri:URI = self.uri(of: .init(natural: index), in: current)
        //             let keywords:[JSON] = declaration.signature.compactMap
        //             {
        //                 switch $0.color 
        //                 {
        //                 case .identifier, .keywordIdentifier, .argument: 
        //                     return JSON.string($0.text)
        //                 default: 
        //                     return nil
        //                 }
        //             }
        //             types.append(.object(
        //             [
        //                 ("s", .array(keywords)),
        //                 ("t", .string(symbol.description)), 
        //                 ("u", .string(uri.description)), 
        //             ]))
        //         }
        //     }
        //     let module:String = .init($0.title)
        //     return .object([("module", .string(module)), ("symbols", .array(types))])
        // }
        // let json:JSON = .array(_move modules)
        // let bytes:[UInt8] = .init((_move json).description.utf8)
        // return .init(hashing: bytes, type: .utf8(encoded: .json))
    }
    
    func generateSiteMap(for package:Package) -> WebResponse.Payload
    {
        fatalError("unimplemented")
        // let domain:String.UTF8View = "https://swiftinit.org".utf8
        // let current:Tree.Pinned = self[package].pinned()
        // // only include natural symbols in a sitemap, since google is likely to 
        // // consider the synthesized ones non-canonical
        // var sitemap:[UInt8] = []
        // for module:Module in current.package.modules.all 
        // {
        //     let uri:URI = self.uri(of: module.index, in: current)
        //     sitemap += domain
        //     sitemap += uri.description.utf8
        //     sitemap.append(0x0a) // '\n'
        // }
        // for module:Module in current.package.modules.all 
        // {
        //     for article:Article.Index in module.articles.joined() 
        //     {
        //         let uri:URI = self.uri(of: article, in: current)
        //         sitemap += domain
        //         sitemap += uri.description.utf8
        //         sitemap.append(0x0a) // '\n'
        //     }
        //     for colony:Symbol.ColonialRange in module.symbols 
        //     {
        //         for offset:Int in colony.offsets 
        //         {
        //             let index:Symbol.Index = .init(module.index, offset: offset)
        //             guard current.package.contains(index, at: current.version)
        //             else 
        //             {
        //                 continue 
        //             }

        //             let uri:URI = self.uri(of: .init(natural: index), 
        //                 in: current)
        //             sitemap += domain
        //             sitemap += uri.description.utf8
        //             sitemap.append(0x0a) // '\n'
        //         }
        //     }
        // }
        // return .init(hashing: sitemap, type: .utf8(encoded: .plain))
    }
}
