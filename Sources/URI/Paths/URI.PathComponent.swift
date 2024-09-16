import Grammar

extension URI
{
    /// A parsing rule that matches a URI path component, which can be empty,
    /// a [`'.'`](), or a [`'..'`](). The dotted components will not be
    /// considered “special” if they are percent-encoded.
    public
    enum PathComponent<Location>
    {
    }
}
extension URI.PathComponent:ParsingRule
{
    public
    typealias Terminal = UInt8
    
    @inlinable public static 
    func parse<Source>(
        _ input:inout ParsingInput<some ParsingDiagnostics<Source>>) throws -> URI.Vector?
        where Source:Collection<UInt8>, Source.Index == Location
    {
        switch try input.parse(as: URI.EncodedString<UnencodedByte>.self)
        {
        case (let string, true):
            switch string 
            {
            case "", ".":   return  nil
            case    "..":   return .pop
            case let next:  return .push(next)
            }
        case (let string, false):
            // component contained at least one percent-encoded character
            return string.isEmpty ? nil : .push(string)
        }
    }
}
