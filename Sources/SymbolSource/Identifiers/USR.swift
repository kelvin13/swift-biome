@frozen public 
enum USR:Hashable, Sendable 
{
    case natural(SymbolIdentifier)
    case synthesized(from:SymbolIdentifier, for:SymbolIdentifier)
}

extension USR:CustomStringConvertible 
{
    @inlinable public 
    var description:String 
    {
        switch self 
        {
        case .natural(let symbol): 
            return symbol.description 
        case .synthesized(from: let base, for: let host):
            return "\(base)::SYNTHESIZED::\(host)"
        }
    }
}
