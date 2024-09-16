@frozen public 
struct Module:AtomicReference, Sendable
{
    public
    let offset:UInt16
    public
    let nationality:Package

    @inlinable public 
    init(_ nationality:Package, offset:UInt16)
    {
        self.nationality = nationality
        self.offset = offset
    }

    @inlinable public 
    var culture:Self
    {
        self
    }
}
