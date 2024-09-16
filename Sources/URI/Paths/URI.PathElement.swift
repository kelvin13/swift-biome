import Grammar

extension URI
{
    /// A parsing rule that matches a ``PathSeparator`` followed by a
    /// ``PathComponent``, whose construction is the construction of the
    /// ``PathComponent``.
    public
    enum PathElement<Location>
    {
    }
}
extension URI.PathElement:ParsingRule
{
    public
    typealias Terminal = UInt8
    
    @inlinable public static 
    func parse<Source>(
        _ input:inout ParsingInput<some ParsingDiagnostics<Source>>) throws -> URI.Vector?
        where Source:Collection<UInt8>, Source.Index == Location
    {
        try input.parse(as: URI.PathSeparator<Location>.self)
        return try input.parse(as: URI.PathComponent<Location>.self)
    }
}
