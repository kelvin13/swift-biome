import SymbolSource 

protocol AnisotropicContext:PackageContext
{
    var local:Tree.Pinned { get }
    var foreign:[Package: Tree.Pinned] { get }

    init(local:Tree.Pinned, context:__shared Trees) 
}
extension AnisotropicContext 
{
    init(local:Package, version:Version, context:__shared Trees) 
    {
        self.init(local: .init(context[local], version: version), context: context)
    }
}
extension AnisotropicContext 
{
    subscript(nationality:Package) -> Tree.Pinned?
    {
        _read 
        {
            yield   self.local.nationality == nationality ? 
                    self.local : self.foreign[nationality]
        }
    }
}
extension AnisotropicContext
{
    func find(_ id:SymbolIdentifier, linked:Set<Module>) 
        -> (AtomicPosition<Symbol>, Symbol.Intrinsic)?
    {
        if  let position:AtomicPosition<Symbol> = self.local.symbols.find(id), 
                linked.contains(position.culture)
        {
            return (position, self.local.tree[local: position]) 
        }
        for upstream:Tree.Pinned in self.foreign.values 
        {
            if  let position:AtomicPosition<Symbol> = upstream.symbols.find(id), 
                    linked.contains(position.culture)
            {
                return (position, upstream.tree[local: position])
            }
        }
        return nil
    }
}