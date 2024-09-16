// 20 B size, 24 B stride
@frozen public
struct Composite:Hashable, Sendable
{
    //  there are up to three cultures that come into play here:
    //  1. host culture 
    //  2. witness culture 
    //  3. perpetrator culture
    public
    let base:Symbol
    public
    let diacritic:Diacritic 
    
    @inlinable public
    init(atomic:Symbol) 
    {
        self.base = atomic
        self.diacritic = .init(atomic: atomic)
    }
    @inlinable public
    init(_ base:Symbol, _ diacritic:Diacritic) 
    {
        self.base = base 
        self.diacritic = diacritic
    }

    @inlinable public
    var culture:Module
    {
        self.diacritic.culture
    }
    @inlinable public
    var nationality:Package
    {
        self.diacritic.nationality 
    }

    @inlinable public
    var isAtomic:Bool 
    {
        self.base == self.diacritic.host
    }
    @inlinable public
    var compound:Compound? 
    {
        .init(diacritic: self.diacritic, base: self.base)
    }
    @inlinable public
    var atom:Symbol? 
    {
        self.isAtomic ? self.base : nil
    }
    @inlinable public
    var host:Symbol? 
    {
        self.isAtomic ? nil : self.diacritic.host 
    }
}
