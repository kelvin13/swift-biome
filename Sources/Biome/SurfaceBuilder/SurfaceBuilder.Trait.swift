import SymbolSource

extension SurfaceBuilder 
{
    enum Trait:Equatable, Sendable
    {
        // members 
        case member(AtomicPosition<Symbol>)
        case feature(AtomicPosition<Symbol>)
        // implementations 
        case implementation(AtomicPosition<Symbol>)
        // downstream
        case refinement(AtomicPosition<Symbol>)
        case subclass(AtomicPosition<Symbol>)
        case override(AtomicPosition<Symbol>)
        // conformers
        case conformer(AtomicPosition<Symbol>, 
            where:[Generic.Constraint<AtomicPosition<Symbol>>])
        // conformances
        case conformance(AtomicPosition<Symbol>, 
            where:[Generic.Constraint<AtomicPosition<Symbol>>])
        
        var feature:AtomicPosition<Symbol>? 
        {
            if case .feature(let feature) = self 
            {
                return feature
            }
            else 
            {
                return nil
            }
        }
    }
}
