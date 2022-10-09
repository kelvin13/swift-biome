import SymbolSource

struct CulturalGraph
{
    let id:ModuleIdentifier 
    let dependencies:[PackageDependency]
    let markdown:[MarkdownFile]
    let colonies:[ColonialGraph]

    init(_ raw:RawCulturalGraph) throws
    {
        self.id = raw.id
        self.dependencies = raw.dependencies.sorted
        {
            $0.package < $1.package
        }
        self.markdown = raw.markdown.sorted
        {
            $0.name < $1.name
        }
        self.colonies = try raw.colonies.map 
        {
            try .init(utf8: $0.utf8, culture: $0.culture, namespace: $0.namespace)
        }
        .sorted 
        { 
            $0.namespace < $1.namespace 
        }
    }
}
