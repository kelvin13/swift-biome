import SymbolSource

@frozen public 
struct PackageDependency:Equatable, Sendable
{
    public
    var nationality:PackageIdentifier
    public
    var cultures:[ModuleIdentifier]
    
    init(nationality:PackageIdentifier, sortedCultures:[ModuleIdentifier])
    {
        self.nationality = nationality 
        self.cultures = sortedCultures
    }
    public 
    init(nationality:PackageIdentifier, cultures:[ModuleIdentifier])
    {
        self.init(nationality: nationality, sortedCultures: cultures.sorted())
    }
}
