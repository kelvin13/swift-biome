extension Symbol 
{
    // should have stride of 16 B, as well as `Scope?` and `Scope??`
    enum Scope:Sendable
    {
        case member(of:AtomicPosition<Symbol>)
        case requirement(of:AtomicPosition<Symbol>)
        
        var role:SurfaceBuilder.Role<AtomicPosition<Symbol>>
        {
            switch self 
            {
            case .member(of: let target):       return .member(of: target)
            case .requirement(of: let target):  return .requirement(of: target)
            }
        }
        var target:AtomicPosition<Symbol> 
        {
            switch self 
            {
            case .member(let target), .requirement(let target): 
                return target
            }
        }
    }
}
