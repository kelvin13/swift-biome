extension Symbol:BranchElement
{
    struct Metadata:Equatable, Sendable
    {
        let roles:Roles<Branch.Position<Symbol>>?
        var primary:Traits<Branch.Position<Symbol>>
        var accepted:[Branch.Position<Module>: Traits<Branch.Position<Symbol>>] 

        init(roles:Roles<Branch.Position<Symbol>>?,
            primary:Traits<Branch.Position<Symbol>>,
            accepted:[Branch.Position<Module>: Traits<Branch.Position<Symbol>>] = [:])
        {
            self.roles = roles
            self.primary = primary
            self.accepted = accepted
        }

        func contains(feature composite:Branch.Composite) -> Bool 
        {
            if  composite.culture == composite.diacritic.host.culture 
            {
                return self.primary.features
                    .contains(composite.base)
            }
            else 
            {
                return self.accepted[composite.culture]?.features
                    .contains(composite.base) ?? false
            }
        }
    }

    public
    struct Divergence:Voidable, Sendable 
    {
        var metadata:_History<Metadata?>.Divergent?
        var declaration:_History<Declaration<Branch.Position<Symbol>>>.Divergent?

        init() 
        {
            self.metadata = nil
            self.declaration = nil
        }
    }

    struct ForeignMetadata:Equatable, Sendable 
    {
        let traits:Traits<Branch.Position<Symbol>>

        init(traits:Traits<Branch.Position<Symbol>>)
        {
            self.traits = traits 
        }

        func contains(feature:Branch.Position<Symbol>) -> Bool 
        {
            self.traits.features.contains(feature)
        }
    }
    
    struct ForeignDivergence:Voidable
    {
        var metadata:_History<ForeignMetadata?>.Divergent?

        init() 
        {
            self.metadata = nil
        }
    }
}
