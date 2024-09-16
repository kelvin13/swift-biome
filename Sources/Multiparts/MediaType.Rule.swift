import Grammar

extension MediaType
{
    @inlinable public
    init(parsing string:some StringProtocol) throws
    {
        self = try Rule<String.Index>.parse(string.utf8)
    }
}

extension MediaType
{
    public
    enum Rule<Location>:ParsingRule 
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> MediaType
            where Source:Collection<UInt8>, Source.Index == Location
        {
            let type:String = try input.parse(as: Multipart.Rule<Location>.Token.self)
            try input.parse(as: UnicodeEncoding<Location, UInt8>.Slash.self)
            let subtype:String = try input.parse(as: Multipart.Rule<Location>.Token.self)

            return .init(type: type.lowercased(), 
                subtype: subtype.lowercased(), 
                parameters: input.parse(as: Multipart.Rule<Location>.Parameter.self, 
                    in: [(name:String, value:String)].self))
        }
    }
}