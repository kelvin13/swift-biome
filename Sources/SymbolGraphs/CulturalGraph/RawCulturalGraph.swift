import SymbolSource 

public
struct RawCulturalGraph:Sendable 
{
    let id:ModuleIdentifier 
    var dependencies:[PackageDependency],
        markdown:[MarkdownFile]
    var colonies:[RawColonialGraph]

    public
    init(id:ModuleIdentifier, 
        dependencies:[PackageDependency] = [],
        markdown:[MarkdownFile] = [], 
        colonies:[RawColonialGraph] = [])
    {
        self.id = id 
        self.dependencies = dependencies
        self.markdown = markdown 
        self.colonies = colonies
    }
}
