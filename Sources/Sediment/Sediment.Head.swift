extension Sediment
{
    @frozen public 
    struct Head:Hashable
    {
        public 
        var index:Index 

        @inlinable public 
        init(_ index:Index)
        {
            self.index = index 
        }
    }
}
