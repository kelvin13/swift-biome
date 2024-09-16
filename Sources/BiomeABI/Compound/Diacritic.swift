@frozen public
struct Diacritic:Hashable, Sendable
{
    public
    let host:Symbol 
    public
    let culture:Module
    
    @inlinable public
    init(host:Symbol, culture:Module)
    {
        self.host = host 
        self.culture = culture
    }
    
    @inlinable public
    init(atomic:Symbol)
    {
        self.host = atomic
        self.culture = atomic.culture
    }

    @inlinable public
    var nationality:Package
    {
        self.culture.nationality
    }
}
