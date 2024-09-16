import JSON
import SymbolGraphs
import SymbolSource
import SystemExtras
@preconcurrency import SystemPackage

public 
enum ColonialGraphLoadingError:Error, CustomStringConvertible 
{
    case invalidName(String, culture:ModuleIdentifier)
    case duplicateNamespace(ModuleIdentifier, culture:ModuleIdentifier)
    
    public 
    var description:String 
    {
        switch self 
        {
        case .invalidName(let string, culture: let culture): 
            return "invalid subgraph name '\(string)' (in culture '\(culture)')"
        case .duplicateNamespace(let namespace, culture: let culture): 
            return "duplicate subgraph namespace '\(namespace)' (in culture '\(culture)')"
        }
    }
}

struct CulturalTarget:Sendable 
{
    let id:ModuleIdentifier
    var include:[FilePath] 
    var dependencies:[PackageDependency]

    init(id:ModuleIdentifier, include:[FilePath], dependencies:[PackageDependency])
    {
        self.id = id 
        self.include = include 
        self.dependencies = dependencies
    }
}
extension CulturalTarget
{
    init(from json:JSON) throws 
    {
        (self.id, self.include, self.dependencies) = try json.lint 
        {
            (
                try $0.remove("id", as: String.self, ModuleIdentifier.init(_:)),
                try $0.remove("include", as: [JSON].self)
                {
                    try $0.map { FilePath.init(try $0.as(String.self)) }
                },
                try $0.remove("dependencies", as: [JSON].self) 
                {
                    try $0.map(PackageDependency.init(from:))
                }
            )
        }
    }
}

extension RawCulturalGraph
{
    init(loading culture:CulturalTarget, relativeTo prefix:FilePath?) throws
    {
        try Task.checkCancellation()
        var paths:
        (
            markdown:[(name:String, source:FilePath)],
            colonies:[ModuleIdentifier: FilePath]
        )
        paths.markdown = []
        paths.colonies = [:]
        for include:FilePath in culture.include
        {
            let include:FilePath = include.isAbsolute  ? include : 
                prefix?.appending(include.components) ?? include
            try include.walk
            {
                (path:FilePath) in 
                
                guard let file:FilePath.Component = path.components.last 
                else 
                {
                    return 
                }
                
                let path:FilePath = include.appending(path.components)
                
                switch file.extension
                {
                case "md"?:
                    paths.markdown.append((file.stem, path))
                
                case "json"?:
                    guard   let reduced:FilePath.Component = .init(file.stem),
                            case "symbols"? = reduced.extension
                    else 
                    {
                        break 
                    }
                    let identifiers:[Substring] = reduced.stem.split(separator: "@", 
                        omittingEmptySubsequences: false)
                    guard case culture.id? = identifiers.first.map(ModuleIdentifier.init(_:))
                    else 
                    {
                        throw ColonialGraphLoadingError.invalidName(reduced.stem, 
                            culture: culture.id)
                    }
                    let namespace:ModuleIdentifier 
                    switch identifiers.count
                    {
                    case 1: 
                        namespace = culture.id 
                    case 2:
                        namespace = .init(identifiers[1])
                    default: 
                        throw ColonialGraphLoadingError.invalidName(reduced.stem, 
                            culture: culture.id)
                    }
                    guard case nil = paths.colonies.updateValue(path, forKey: namespace)
                    else 
                    {
                        throw ColonialGraphLoadingError.duplicateNamespace(namespace, 
                            culture: culture.id)
                    }
                    
                default: 
                    break
                }
            }
        }

        self.init(id: culture.id, dependencies: culture.dependencies,
            markdown: try paths.markdown.map 
            {
                .init(name: $0.name, 
                    source: try $0.source.read(String.self))
            }, 
            colonies: try paths.colonies.map 
            {
                .init(namespace: $0.key, culture: culture.id, 
                    utf8: try $0.value.read([UInt8].self))
            })
    }
}
