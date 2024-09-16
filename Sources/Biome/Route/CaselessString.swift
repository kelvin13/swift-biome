import SymbolSource

@frozen public 
struct CaselessString:Hashable, Sendable
{
    public 
    let lowercased:String 

    @inlinable public
    init(lowercased:String)
    {
        self.lowercased = lowercased
    }

    @inlinable public
    init(_ string:some StringProtocol)
    {
        self.init(lowercased: string.lowercased())
    }

    init(_ namespace:ModuleIdentifier)
    {
        self.init(lowercased: namespace.value)
    }
}
extension CaselessString:ExpressibleByStringLiteral 
{
    @inlinable public 
    init(stringLiteral:String)
    {
        self.init(stringLiteral)
    }
}
