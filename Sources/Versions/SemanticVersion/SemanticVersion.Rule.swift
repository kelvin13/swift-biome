import Grammar 

extension SemanticVersion
{
    @inlinable public 
    init(parsing string:some StringProtocol) throws 
    {
        self = try Rule<String.Index>.parse(string.unicodeScalars)
    }
}
extension SemanticVersion.Masked 
{
    @inlinable public 
    init(parsing string:some StringProtocol) throws 
    {
        self = try SemanticVersion.Rule<String.Index>.Masked.parse(string.unicodeScalars)
    }
}
extension SemanticVersion 
{
    public 
    enum Rule<Location>
    {
        public 
        typealias Terminal = Unicode.Scalar
        public 
        typealias Encoding = UnicodeEncoding<Location, Terminal>
    }
}
extension SemanticVersion.Rule:ParsingRule
{
    public 
    typealias Integer = Pattern.UnsignedInteger<
        UnicodeDigit<Location, Unicode.Scalar, UInt16>.DecimalScalar>
    public 
    typealias Period = UnicodeEncoding<Location, Unicode.Scalar>.Period

    @inlinable public static 
    func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
        throws -> SemanticVersion
        where Source:Collection<Unicode.Scalar>, Source.Index == Location
    {
        let major:UInt16 = try input.parse(as: Integer.self)
        try input.parse(as: Period.self)
        let minor:UInt16 = try input.parse(as: Integer.self)
        try input.parse(as: Period.self)
        let patch:UInt16 = try input.parse(as: Integer.self)
        return .init(major, minor, patch)
    }

    public 
    enum Masked:ParsingRule 
    {
        public
        typealias Terminal = Unicode.Scalar
        
        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> SemanticVersion.Masked
            where Source:Collection<Unicode.Scalar>, Source.Index == Location
        {
            let first:UInt16 = try input.parse(as: Integer.self)

            guard case let (_, minor)? = 
                try? input.parse(as: (Encoding.Period, Integer).self)
            else 
            {
                return .major(first)
            }
            guard case let (_, patch)? = 
                try? input.parse(as: (Encoding.Period, Integer).self)
            else 
            {
                return .minor(first, minor)
            }

            return .patch(first, minor, patch)
        }
    }
}
