@frozen public 
struct Symbol:AtomicReference, Sendable
{
    public
    let offset:UInt32
    public
    let culture:Module

    @inlinable public 
    init(_ culture:Module, offset:UInt32)
    {
        self.culture = culture
        self.offset = offset
    }
}
