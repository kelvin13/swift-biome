import SymbolSource

@frozen public
struct SnippetFile:Equatable
{
    public
    let name:ModuleIdentifier
    public
    let dependencies:[PackageDependency]
    public
    let source:String

    public
    init(name:ModuleIdentifier, dependencies:[PackageDependency], source:String)
    {
        self.name = name
        self.source = source
        self.dependencies = dependencies.sorted { $0.nationality < $1.nationality }
    }
}