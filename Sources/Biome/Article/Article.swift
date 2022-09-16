import struct SymbolGraphs.Path
import HTML

@usableFromInline 
struct Article:Sendable
{
    @usableFromInline 
    typealias Culture = Module.Index 
    @usableFromInline 
    typealias Offset = UInt32 

    @usableFromInline 
    struct ID:Hashable, Sendable 
    {
        let route:Route.Key
        
        init(_ route:Route.Key)
        {
            self.route = route
        }
        init(_ culture:Branch.Position<Module>, _ stem:Route.Stem, _ leaf:Route.Stem)
        {
            self.init(.init(culture, stem, .init(leaf, orientation: .straight)))
        }
    }

    @usableFromInline 
    let id:ID 
    var path:Path

    var metadata:_History<Metadata?>.Head?
    var documentation:_History<DocumentationExtension<Never>>.Head?
    
    init(id:ID, path:Path)
    {
        self.id = id
        self.path = path

        self.metadata = nil 
        self.documentation = nil
    }

    var name:String 
    {
        self.path.last
    }
    var route:Route.Key 
    {
        self.id.route
    }
}
