import Grammar

extension URI
{
    /// A parsing rule that matches a path separator character
    /// ([`'/'`]() or [`'\'`]()).
    public
    enum PathSeparator<Location>
    {
    }
}
extension URI.PathSeparator:TerminalRule
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
        //    '/'   '\'
        case 0x2f, 0x5c: return ()
        default: return nil
        }
    }
}
