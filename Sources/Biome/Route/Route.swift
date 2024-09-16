struct Route:Hashable, Sendable, CustomStringConvertible 
{
    let namespace:Module
    let stem:Stem 
    let leaf:Leaf 
    
    var outed:Self? 
    {
        self.leaf.outed.map { .init(self.namespace, self.stem, $0) }
    }
    
    var description:String 
    {
        """
        \(self.namespace.nationality.offset):\
        \(self.namespace.offset).\
        \(self.stem.bitPattern >> 1).\
        \(self.leaf.bitPattern)
        """
    }
    
    init(_ namespace:Module, _ stem:Stem, _ leaf:Stem, orientation:_SymbolLink.Orientation)
    {
        self.init(namespace, stem, .init(leaf, orientation: orientation))
    }
    init(_ namespace:Module, _ stem:Stem, _ leaf:Leaf)
    {
        self.namespace = namespace
        self.stem = stem
        self.leaf = leaf
    }
    
    func first<T>(where transform:(Self) throws -> T?) rethrows -> (T, redirected:Bool)? 
    {
        if      let result:T = try transform(self)
        {
            return (result, false)
        }
        else if let outed:Self = self.outed, 
                let result:T = try transform(outed)
        {
            return (result, true)
        }
        else 
        {
            return nil
        }
    }
}