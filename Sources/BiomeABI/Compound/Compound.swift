/// A compound symbol. 
/// 
/// This type provides a static guarantee that [`self.host != self.base`]().
@frozen public
struct Compound:Hashable, Sendable
{
    public
    let base:Symbol
    public
    let diacritic:Diacritic
    
    @inlinable public
    init?(diacritic:Diacritic, base:Symbol)
    {
        guard diacritic.host != base 
        else 
        {
            return nil 
        }
        self.diacritic = diacritic 
        self.base = base 
    }

    @inlinable public
    var host:Symbol
    {
        self.diacritic.host 
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
}
