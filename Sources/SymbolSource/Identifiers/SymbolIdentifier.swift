@frozen public
struct SymbolIdentifier:Sendable 
{
    @frozen public 
    enum Language:Unicode.Scalar, Hashable, Sendable 
    {
        case c      = "c"
        case swift  = "s"
    }

    // this must always be an ASCII string
    public 
    let string:String 
    
    @inlinable public 
    init(unchecked:String)
    {
        self.string = unchecked
    }
    @inlinable public 
    init(_ language:Language, _ mangled:some Collection<UInt8>)
    {
        self.string = 
        """
        \(language.rawValue)\(String.init(decoding: mangled, as: Unicode.ASCII.self))
        """
    }
    
    @inlinable public 
    var language:Language 
    {
        if  let language:Language = 
                self.string.unicodeScalars.first.flatMap(Language.init(rawValue:))
        {
            return language 
        }
        else 
        {
            // should always be round-trippable
            fatalError("unreachable: unknown symbol language prefix!")
        }
    }
}
extension SymbolIdentifier:Equatable
{
    @inlinable public static
    func == (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.string.utf8.elementsEqual(rhs.string.utf8)
    }
}
extension SymbolIdentifier:Hashable 
{
    @inlinable public 
    func hash(into hasher:inout Hasher) 
    {
        for byte:UInt8 in self.string.utf8
        {
            byte.hash(into: &hasher)
        }
    }
}
extension SymbolIdentifier:Comparable
{
    @inlinable public static
    func < (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.string.utf8.lexicographicallyPrecedes(rhs.string.utf8)
    }
}
extension SymbolIdentifier:CustomStringConvertible
{
    @inlinable public
    var description:String
    {
        self.string
    }
}