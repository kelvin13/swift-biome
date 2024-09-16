import Grammar

extension URI 
{
    public 
    enum Expression<Location>
    {
    }
}
extension URI.Expression:ParsingRule
{
    public
    typealias Terminal = UInt8

    @inlinable public static 
    func parse<Source>(
        _ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
        throws -> (absolute:Bool, uri:URI)
        where Source:Collection<UInt8>, Source.Index == Location
    {
        if let uri:URI = input.parse(as: URI.Absolute<Location>?.self)
        {
            return (true, uri) 
        }
        else 
        {
            return (false, try input.parse(as: URI.Relative<Location>.self))
        }
    }
}
