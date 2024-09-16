extension Overlay
{
    struct Metadata:Equatable, Sendable 
    {
        let traits:Branch.SymbolTraits

        init(traits:Branch.SymbolTraits)
        {
            self.traits = traits 
        }

        func contains(feature:Symbol) -> Bool 
        {
            self.traits.features.contains(feature)
        }
    }
}