import JSON
import SymbolGraphs
import SymbolSource
@preconcurrency import SystemPackage

struct SnippetTarget:Sendable 
{
    let id:ModuleIdentifier
    var sources:[FilePath] 
    var dependencies:[PackageDependency]
    
    init(id:ModuleIdentifier, sources:[FilePath], dependencies:[PackageDependency])
    {
        self.id = id 
        self.sources = sources 
        self.dependencies = dependencies
    }
}
extension SnippetTarget
{
    init(from json:JSON) throws 
    {
        (self.id, self.sources, self.dependencies) = try json.lint 
        {
            (
                try $0.remove("id", as: String.self, ModuleIdentifier.init(_:)),
                try $0.remove("sources", as: [JSON].self)
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

extension SnippetFile
{
    init(loading snippet:SnippetTarget, relativeTo prefix:FilePath?) throws
    {
        self.init(name: snippet.id, dependencies: snippet.dependencies,
            source: try snippet.sources.map
            {
                let path:FilePath = $0.isAbsolute     ? $0 : 
                    prefix?.appending($0.components) ?? $0
                return try path.read()
            }.joined(separator: "\n"))
    }
}