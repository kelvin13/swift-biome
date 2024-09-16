import Grammar

extension DispositionType
{
    public 
    enum Rule<Location>:ParsingRule 
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> DispositionType
            where Source:Collection<UInt8>, Source.Index == Location
        {
            let type:String = try input.parse(as: Multipart.Rule<Location>.Token.self)
            return .init(type: type.lowercased(), 
                parameters: input.parse(as: Multipart.Rule<Location>.Parameter.self, 
                    in: [(name:String, value:String)].self))
        }
    }
}