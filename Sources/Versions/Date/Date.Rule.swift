import Grammar 

extension Date 
{
    @inlinable public 
    init(parsing string:some StringProtocol) throws 
    {
        self = try Rule<String.Index>.parse(string.unicodeScalars)
    }
}
extension Date 
{
    public 
    struct Rule<Location>:ParsingRule
    {
        public 
        typealias Terminal = Unicode.Scalar
        public 
        typealias Encoding = UnicodeEncoding<Location, Terminal>

        public 
        typealias Integer = Pattern.UnsignedInteger<
            UnicodeDigit<Location, Unicode.Scalar, UInt16>.DecimalScalar>

        public 
        enum Hour:TerminalRule
        {
            public 
            typealias Terminal = Unicode.Scalar
            public 
            typealias Construction = UInt8
            
            @inlinable public static 
            func parse(terminal:Unicode.Scalar) -> UInt8?
            {
                switch terminal 
                {
                case "a" ... "z":   return .init(ascii: terminal)
                default:            return nil
                }
            }
        }

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> Date
            where Source:Collection<Unicode.Scalar>, Source.Index == Location
        {
            let gregorian:UInt16 = try input.parse(as: Integer.self)
            try input.parse(as: Encoding.Hyphen.self)
            let month:UInt16 = try input.parse(as: Integer.self)
            try input.parse(as: Encoding.Hyphen.self)
            let day:UInt16 = try input.parse(as: Integer.self)
            let hour:UInt8 
            if case let (_, letter)? = try? input.parse(as: (Encoding.Hyphen, Hour).self)
            {
                hour = letter 
            }
            else 
            {
                hour = 0x61
            }
            let year:Date.Year = try .init(gregorian: gregorian)
            return try .init(year: year, month: month, day: day, hour: hour)
        }
    }
}