import Grammar

extension URI 
{
    /// A parsing rule that matches a relative URI, such as
    /// [`'foo/bar/baz?a=x&b=y'`](). Parsing an absolute URI with this
    /// rule will generate a URI with an empty leading path vector.
    ///
    /// Parsing a root expression ([`'/'`]()) with this rule produces
    /// a ``URI`` with two [`nil`]() path vectors.
    public 
    enum Relative<Location>
    {
    }
}
extension URI.Relative:ParsingRule
{
    public
    typealias Terminal = UInt8
    
    @inlinable public static 
    func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
        throws -> URI
        where Source:Collection<UInt8>, Source.Index == Location
    {
        var path:[URI.Vector?] = [try input.parse(as: URI.PathComponent<Location>.self)]
        while let next:URI.Vector? = input.parse(as: URI.PathElement<Location>?.self)
        {
            path.append(next)
        }
        let query:[URI.Parameter]? = input.parse(as: URI.Query<Location>?.self)
        return .init(path: path, query: query)
    }
}
