import Grammar 

extension USR 
{
    @inlinable public 
    init<UTF8>(parsing utf8:UTF8) throws where UTF8:Collection<UInt8>
    {
        self = try Rule<UTF8.Index>.parse(utf8)
    }
}
extension USR 
{
    public
    enum Rule<Location>
    {
        public 
        typealias Terminal = UInt8
        public 
        typealias Encoding = UnicodeEncoding<Location, Terminal>
    }
}
// it would be really nice if this were generic over ``ASCIITerminal``
extension USR.Rule:ParsingRule 
{
    // USR  ::= <Mangled Name> ( '::SYNTHESIZED::' <Mangled Name> ) ?
    @inlinable public static 
    func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
        throws -> USR
        where Source:Collection<UInt8>, Source.Index == Location
    {
        let first:SymbolIdentifier = try input.parse(as: SymbolIdentifier.Rule<Location>.self)
        guard let _:Void = input.parse(as: Synthesized?.self)
        else 
        {
            return .natural(first)
        }
        let second:SymbolIdentifier = try input.parse(as: SymbolIdentifier.Rule<Location>.self)
        return .synthesized(from: first, for: second)
    }

    public 
    enum Synthesized:LiteralRule 
    {
        public
        typealias Terminal = UInt8

        @inlinable public static 
        var literal:[UInt8] 
        {
            // '::SYNTHESIZED::'
            [
                0x3a, 0x3a, 
                0x53, 0x59, 0x4e, 0x54, 0x48, 0x45, 0x53, 0x49, 0x5a, 0x45, 0x44, 
                0x3a, 0x3a
            ]
        }
    }
}
