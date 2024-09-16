extension Sediment
{
    @frozen public 
    struct StratumIterator:Sequence, IteratorProtocol 
    {
        public 
        var current:Index? 
        public 
        let sediment:Sediment<Instant, Value>

        @inlinable public 
        init(current:Index?, sediment:Sediment<Instant, Value>)
        {
            self.current = current 
            self.sediment = sediment
        }
        @inlinable public mutating 
        func next() -> (value:Value, since:Instant)?
        {
            if let current:Index = self.current
            {
                self.current = self.sediment.predecessor(of: current) 
                let bed:Bed = self.sediment[current]
                return (bed.value, bed.since)
            }
            else 
            {
                return nil 
            }
        }
    }
}