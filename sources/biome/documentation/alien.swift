protocol GreenAlien 
{
    var stem:[[UInt8]] 
    {
        get 
    }
    var leaf:[UInt8]
    {
        get 
    }
}
extension Documentation 
{
    struct Marque 
    {
        let trunk:Int
        let whitelist:Set<Int>
            
        var context:UnresolvedLinkContext
        {
            // *not* `self.stem`!
            .init(whitelist: self.whitelist, greenzone: (self.trunk, []))
        }
    }
    struct Expatriate<Conquistador> where Conquistador:GreenAlien
    {
        let conquistador:Conquistador
        let marque:Marque
        
        var trunk:Int
        {
            self.marque.trunk 
        }
        var stem:[[UInt8]]
        {
            self.conquistador.stem 
        }
        var leaf:[UInt8]
        {
            self.conquistador.leaf
        }
        
        func map<T>(_ transform:(Conquistador, UnresolvedLinkContext) throws -> T) 
            rethrows -> Expatriate<T>
        {
            .init(conquistador: try transform(self.conquistador, self.marque.context), marque: self.marque)
        }
    }
}