extension Sediment
{
    @inlinable public 
    subscript(head:Head?) -> Stratum 
    {
        .init(head, sediment: self)
    }
}
extension Sediment
{
    /// A view into a sedimentary buffer tracing the history of a particular 
    /// head. Iterating forward through this sequence travels backward in time.
    /// In other words, the first element of this sequence is the most 
    /// recently-deposited value in the stratum.
    @frozen public 
    struct Stratum:Sequence
    {
        public 
        let head:Head?
        public 
        let sediment:Sediment<Instant, Value>

        @inlinable public 
        func makeIterator() -> StratumIterator
        {
            .init(current: self.head?.index, sediment: self.sediment)
        }

        @inlinable public 
        init(_ head:Head?, sediment:Sediment<Instant, Value>)
        {
            self.head = head 
            self.sediment = sediment
        }

        /// ```text 
        /// indices :           a                           b   c
        ///         :           ↓                           ↓   ↓
        /// ages    :   0   1   2   3   4   5   6   7   8   9   A   B
        ///         :   ──────┐───────────────────────────┐───┐───────
        /// result  :  nil nil│ a   a   a   a   a   a   a │ b │ c   c
        ///             ──────└───────────────────────────└───└───────
        /// ``` 
        @inlinable public 
        func find(_ time:Instant) -> Index?
        {
            guard var current:Index = self.head?.index
            else 
            {
                return nil
            }

            guard time < self.sediment[current].since
            else 
            {
                return current 
            }

            var bound:Index? = nil 
            // ascend
            while let parent:Index = self.sediment.parent(of: current)
            {
                let since:Instant = self.sediment[parent].since
                if      time < since
                {
                    current = parent
                }
                else if since < time, 
                    let left:Index = self.sediment.left(of: current) 
                {
                    // because ascension can skip elements, we don’t 
                    // know if this is the *last* element where `since <= time`,
                    // so we need to check the left subtree of the child.
                    current = left
                    bound = parent 
                    break 
                }
                else 
                {
                    return parent 
                }
            }
            // descend
            while true 
            {
                let since:Instant = self.sediment[current].since
                if      time < since
                {
                    guard   let left:Index = self.sediment.left(of: current)
                    else 
                    {
                        break 
                    }
                    current = left 
                }
                else 
                {
                    bound = current 
                    guard   since < time, 
                            let right:Index = self.sediment.right(of: current) 
                    else 
                    {
                        break 
                    }
                    current = right
                }
            }
            return bound 
        }
    }
}

extension Sediment.Stratum:CustomStringConvertible 
{
    public 
    var description:String
    {
       self.head.map 
       {
            self.sediment.description(head: $0, root: self.sediment.root(of: $0.index))
       } ?? "nil"
    }
}