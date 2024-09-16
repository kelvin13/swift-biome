import Grammar

extension URI
{
    /// A parsing rule that matches a query separator character
    /// ([`'&'`]() or [`';'`]()).
    public
    enum QuerySeparator<Location>
    {
    }
}
extension URI.QuerySeparator:TerminalRule
{
    public
    typealias Terminal = UInt8
    public
    typealias Construction = Void 
    
    @inlinable public static 
    func parse(terminal:Terminal) -> Void?
    {
        switch terminal
        {
        //    '&'   ';' 
        case 0x26, 0x3b: 
            return ()
        default:
            return nil
        }
    }
}
