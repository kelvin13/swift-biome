import SymbolSource

struct Namespaces
{
    let id:ModuleIdentifier
    let module:AtomicPosition<Module>
    var linked:[ModuleIdentifier: AtomicPosition<Module>]

    init(_ module:AtomicPosition<Module>, id:ModuleIdentifier)
    {
        self.linked = [id: module]
        self.module = module
        self.id = id 
    }

    var nationality:Package
    {
        self.culture.nationality
    }
    var culture:Module 
    {
        self.module.atom
    }

    /// Returns a set containing all modules the current module depends on. 
    /// 
    /// This is similar to ``import``, except it excludes the current module.
    func dependencies() -> Set<Module>
    {
        .init(self.linked.values.lazy.compactMap 
        { 
            $0.atom == self.culture ? nil : $0.atom 
        })
    }
    /// Returns a set containing all modules that can be imported, including the 
    /// current module.
    func `import`() -> Set<Module>
    {
        .init(self.linked.values.lazy.map(\.atom))
    }
    
    /// Returns a set containing all modules that can be imported, among the requested 
    /// list of module names. The current module is always included in the set, 
    /// even if not explicitly requested.
    func `import`(_ modules:some Sequence<ModuleIdentifier>) -> Set<Module>
    {
        var imported:Set<Module> = []
            imported.reserveCapacity(modules.underestimatedCount + 1)
        for module:ModuleIdentifier in modules 
        {
            if let element:Module = self.linked[module]?.atom
            {
                imported.insert(element)
            }
        }
        imported.insert(self.culture)
        return imported
    }
}