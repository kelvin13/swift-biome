extension Symbol
{
    struct Metadata:Equatable, Sendable
    {
        let roles:Branch.SymbolRoles?
        var primary:Branch.SymbolTraits
        var accepted:[Module: Branch.SymbolTraits] 

        init(roles:Branch.SymbolRoles?,
            primary:Branch.SymbolTraits,
            accepted:[Module: Branch.SymbolTraits] = [:])
        {
            self.roles = roles
            self.primary = primary
            self.accepted = accepted
        }

        func contains(feature:Compound) -> Bool 
        {
            feature.culture == feature.host.culture ?
                self.primary.features.contains(feature.base) :
                self.accepted[feature.culture]?.features.contains(feature.base) ?? false
        }
    }
}
