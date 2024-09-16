import JSON
import SymbolSource

extension Generic.ConstraintVerb 
{
    // https://github.com/apple/swift/blob/e7d56037e87787c3ee92d861e95e5ba95e0bcbd4/lib/SymbolGraphGen/JSON.cpp#L92
    enum Longform:String 
    {
        case superclass
        case conformance
        case sameType
    }
}
extension Generic.Constraint<SymbolIdentifier>
{
    init(lowering json:JSON) throws
    {
        self = try json.lint 
        {
            let verb:Generic.ConstraintVerb = try $0.remove("kind") 
            {
                switch try $0.as(cases: Generic.ConstraintVerb.Longform.self)
                {
                case .superclass:   return .subclasses
                case .conformance:  return .implements
                case .sameType:     return .is
                }
            }
            return .init(
                try    $0.remove("lhs", as: String.self), verb, 
                try    $0.remove("rhs", as: String.self), 
                target: try $0.pop("rhsPrecise", SymbolIdentifier.init(from:)))
        }
    }
}
