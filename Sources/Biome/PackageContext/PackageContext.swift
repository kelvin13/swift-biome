protocol PackageContext 
{
    subscript(nationality:Package) -> Tree.Pinned?
    {
        get 
    }
}

extension PackageContext 
{
    func load(_ symbol:Symbol) -> Symbol.Intrinsic?
    {
        self[symbol.nationality]?.load(local: symbol) 
    }
}
extension PackageContext 
{
    func address(of atomic:Symbol, 
        disambiguate:Address.DisambiguationLevel = .minimally) -> Address?
    {
        self[atomic.nationality]?.address(of: atomic, 
            disambiguate: disambiguate, 
            context: self)
    }
}
extension PackageContext 
{
    func documentation(for symbol:inout Symbol) -> DocumentationExtension<Never>?
    {
        while   let documentation:DocumentationExtension<Symbol> = 
                    self[symbol.nationality]?.documentation(for: symbol)
        {
            guard   documentation.card.isEmpty, 
                    documentation.body.isEmpty 
            else 
            {
                let documentation:DocumentationExtension<Never> = .init(
                    errors: documentation.errors, 
                    card: documentation.card, 
                    body: documentation.body)
                return documentation
            }
            guard   let next:Symbol = documentation.extends, 
                        next != symbol // sanity check
            else 
            {
                break 
            }
            symbol = next
        }
        return nil
    }
    func documentation(for symbol:Symbol) -> DocumentationExtension<Never>?
    {
        var ignored:Symbol = symbol 
        return self.documentation(for: &ignored)
    }
}
