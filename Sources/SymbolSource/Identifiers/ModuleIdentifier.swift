@frozen public
struct ModuleIdentifier:Sendable
{
    public
    let string:String 

    @inlinable public
    init(_ string:some StringProtocol)
    {
        self.string = .init(string)
    }
}
extension ModuleIdentifier:Equatable 
{
    @inlinable public 
    var title:Substring 
    {
        self.string.drop { $0 == "_" } 
    }
    // lowercased. it is possible for lhs == rhs even if lhs.string != rhs.string
    @inlinable public 
    var value:String 
    {
        self.title.lowercased()
    }
    @inlinable public static 
    func == (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.value == rhs.value
    }
}
extension ModuleIdentifier:Hashable 
{
    @inlinable public 
    func hash(into hasher:inout Hasher) 
    {
        self.value.hash(into: &hasher)
    }
}
extension ModuleIdentifier:Comparable
{
    @inlinable public static
    func < (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.value < rhs.value
    }
}
extension ModuleIdentifier:ExpressibleByStringLiteral 
{
    @inlinable public
    init(stringLiteral:String)
    {
        self.string = stringLiteral
    }
}
extension ModuleIdentifier:CustomStringConvertible
{
    @inlinable public 
    var description:String 
    {
        self.string 
    }
}
extension ModuleIdentifier:Decodable 
{
    @inlinable public 
    init(from decoder:any Decoder) throws 
    {
        self.init(try decoder.singleValueContainer().decode(String.self))
    }
}