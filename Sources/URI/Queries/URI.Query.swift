import Grammar

extension URI
{
    /// A parsing rule that matches a leading question mark ([`'?'`]()),
    /// followed by zero or more ``QueryComponent``s separated by
    /// ``QuerySeparator``s.
    public
    enum Query<Location>
    {
    }
}
extension URI.Query:ParsingRule
{
    public 
    typealias Terminal = UInt8
    
    @inlinable public static 
    func parse<Source>(
        _ input:inout ParsingInput<some ParsingDiagnostics<Source>>) throws -> [URI.Parameter]
        where Source:Collection<UInt8>, Source.Index == Location
    {
        try input.parse(as: UnicodeEncoding<Location, UInt8>.Question.self)
        return input.parse(
            as: Pattern.Join<URI.QueryComponent<Location>, URI.QuerySeparator<Location>,
                [URI.Parameter]>?.self) ?? []
    }
}
