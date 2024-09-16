extension Sediment
{
    /// A table suitable for correcting indices that may have been invalidated 
    /// by an ``erode(until:)`` operation.
    ///
    /// Erosion operations remove elements from sediment. Therefore references
    /// to elements that were eroded away must be rewound to the last point in 
    /// their history where they still remain, or discarded if no prior 
    /// snapshot remains.
    @frozen public
    struct Rollbacks
    {
        public
        var table:[Index: Index]
        public
        var threshold:Index

        @inlinable public
        init(compressing uptree:[Index: Head?], threshold:Index)
        {
            self.threshold = threshold
            var table:[Index: Head?] = [:]
            for (current, next):(Index, Head?) in uptree 
                where !table.keys.contains(current)
            {
                var keys:[Index] = [current]
                var value:Head? = next 
                while   let current:Index = value?.index,
                        let next:Head? = uptree[current]
                {
                    keys.append(current)
                    value = next 
                }
                for key:Index in keys
                {
                    table[key] = value
                }
            }
            self.table = table.compactMapValues { $0?.index }
        }
        @inlinable public
        subscript(index:Index) -> Index?
        {
            index < self.threshold ? index : self.table[index]
        }
        @inlinable public
        subscript(head:Head) -> Head?
        {
            self[head.index].map(Head.init(_:))
        }
    }
}