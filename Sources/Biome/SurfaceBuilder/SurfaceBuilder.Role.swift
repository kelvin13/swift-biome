extension SurfaceBuilder.Role:Equatable where Position:Equatable {}
extension SurfaceBuilder.Role:Hashable where Position:Hashable {}
extension SurfaceBuilder.Role:Sendable where Position:Sendable {}
extension SurfaceBuilder 
{
    @frozen public
    enum Role<Position>:CustomStringConvertible
    {
        case member(of:Position)
        case implementation(of:Position)
        case refinement(of:Position)
        case subclass(of:Position)
        case override(of:Position)
        
        case interface(of:Position)
        case requirement(of:Position)
        
        func map<T>(_ transform:(Position) throws -> T) rethrows -> Role<T>
        {
            switch self 
            {
            case .member(of: let target): 
                return .member(of: try transform(target))
            case .implementation(of: let target): 
                return .implementation(of: try transform(target))
            case .refinement(of: let target): 
                return .refinement(of: try transform(target))
            case .subclass(of: let target): 
                return .subclass(of: try transform(target))
            case .override(of: let target): 
                return .override(of: try transform(target))
            case .interface(of: let target): 
                return .interface(of: try transform(target))
            case .requirement(of: let target): 
                return .requirement(of: try transform(target))
            }
        }
        @inlinable public
        var description:String 
        {
            switch self 
            {
            case .member(of: let target): 
                return "member of \(target)"
            case .implementation(of: let target): 
                return "implementation of \(target)"
            case .refinement(of: let target): 
                return "refinement of \(target)"
            case .subclass(of: let target): 
                return "subclass of \(target)"
            case .override(of: let target): 
                return "override of \(target)"
            case .interface(of: let target): 
                return "interface of \(target)"
            case .requirement(of: let target): 
                return "requirement of \(target)"
            }
        }
    }
}
