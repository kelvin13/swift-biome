import SymbolGraphs
import SymbolSource
import SystemPackage
import Grammar
import JSON

public 
enum BuildError:Error
{
    case toolsVersion(Int)
}

public 
struct Build:Sendable 
{
    let id:PackageIdentifier
    let cultures:[CulturalTarget]
    let snippets:[SnippetTarget]
    
    init(id:PackageIdentifier, cultures:[CulturalTarget] = [], snippets:[SnippetTarget] = [])
    {
        self.id = id 
        self.cultures = cultures
        self.snippets = snippets
    }
    public
    init(from json:JSON) throws
    {
        self = try json.lint 
        {
            switch try $0.remove("symbolgraph_tools_version", as: Int.self)
            {
            case 4:
                return .init(
                    id: try $0.remove("id", as: String.self, PackageIdentifier.init(_:)), 
                    cultures: try $0.pop("cultures", as: [JSON].self)
                    {
                        try $0.map(CulturalTarget.init(from:))
                    } ?? [], 
                    snippets: try $0.pop("snippets", as: [JSON].self)
                    {
                        try $0.map(SnippetTarget.init(from:))
                    } ?? [])

            case let unsupported:
                throw BuildError.toolsVersion(unsupported)
            }
        }
    }
}
extension RangeReplaceableCollection<Build>
{
    @inlinable public 
    init<UTF8>(parsing utf8:UTF8) throws where UTF8:Collection<UInt8>
    {
        let json:[JSON] = try JSON.Rule<UTF8.Index>.Array.parse(utf8)
        self.init()
        self.reserveCapacity(json.count)
        for json:JSON in json
        {
            self.append(try .init(from: json))
        }
    }
}

extension RawSymbolGraph
{
    public
    init(loading build:Build, relativeTo prefix:FilePath? = nil) throws
    {
        self.init(id: build.id, 
            cultures: try build.cultures.map
            {
                try .init(loading: $0, relativeTo: prefix)
            }, 
            snippets: try build.snippets.map
            {
                try .init(loading: $0, relativeTo: prefix)
            })
    }
}