import Grammar

extension URI 
{
    /// A parsing rule that matches an absolute URI, such as
    /// [`'/foo/bar/baz?a=x&b=y'`](). Parsing a relative URI with this
    /// rule will throw an error.
    ///
    /// Parsing a root expression ([`'/'`]()) with this rule produces
    /// a ``URI`` with a single [`nil`]() path vector.
    public 
    enum Absolute<Location>
    {
    }
}

extension URI.Absolute:ParsingRule 
{
    public
    typealias Terminal = UInt8

    @inlinable public static 
    func parse<Source>(
        _ input:inout ParsingInput<some ParsingDiagnostics<Source>>) throws -> URI
        where Source:Collection<UInt8>, Source.Index == Location
    {
        //  i. lexical segmentation and percent-decoding 
        //
        //  '//foo/bar/.\bax.qux/..//baz./.Foo/%2E%2E//' becomes 
        // ['', 'foo', 'bar', < None >, 'bax.qux', < Self >, '', 'baz.bar', '.Foo', '..', '', '']
        // 
        //  the first slash '/' does not generate an empty component.
        //  this is the uri we percieve as the uri entered by the user, even 
        //  if their slash ('/' vs '\') or percent-encoding scheme is different.
        let path:[URI.Vector?] = try input.parse(
            as: Pattern.Reduce<URI.PathElement<Location>, [URI.Vector?]>.self)
        let query:[URI.Parameter]? = input.parse(as: URI.Query<Location>?.self)
        return .init(path: path, query: query)
    }
}
