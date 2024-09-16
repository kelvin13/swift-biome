extension Forest 
{
    @inlinable public 
    subscript(tree:Tree.Head?) -> Tree 
    {
        .init(tree, forest: self)
    }

    @frozen public 
    struct Tree:Sequence
    {
        @frozen public 
        struct Head
        {
            public 
            var index:Index 

            @inlinable public 
            init(_ index:Index)
            {
                self.index = index 
            }
        }
        @frozen public 
        struct Iterator:IteratorProtocol 
        {
            public 
            var current:Index? 
            public 
            let forest:Forest<Value>

            @inlinable public 
            init(current:Index?, forest:Forest<Value>)
            {
                self.current = current 
                self.forest = forest 
            }
            @inlinable public mutating 
            func next() -> Value?
            {
                if let current:Index = self.current
                {
                    self.current = self.forest.successor(of: current) 
                    return self.forest[current].value
                }
                else 
                {
                    return nil 
                }
            }
        }

        public 
        let head:Head?
        public 
        let forest:Forest<Value>

        @inlinable public 
        func makeIterator() -> Iterator
        {
            .init(current: self.head?.index, forest: self.forest)
        }

        @inlinable public 
        init(_ head:Head?, forest:Forest<Value>)
        {
            self.head = head 
            self.forest = forest
        }

        @available(*, deprecated)
        @inlinable public 
        func find(by less:(Value) throws -> Bool?) rethrows -> Index?
        {
            if case (let index, nil)? = try self.walk(by: less)
            {
                return index 
            }
            else 
            {
                return nil
            }
        }

        /// Returns the index of the first element in the tree that matches the 
        /// given predicate, assuming that the elements are ordered such that 
        /// if an arbitrary element matches the predicate, then all subsequent 
        /// elements do so as well.
        ///
        /// The following diagram illustrates the output for a tree with 3 values, 
        /// and a predicate of [`{ $0 >= x }`](), over `x` in [`0x0 ... 0xB`]().
        /// 
        /// ```text 
        /// indices :               a   b                       c
        ///         :               ↓   ↓                       ↓
        /// values  :   0   1   2   3   4   5   6   7   8   9   A   B
        ///         :   ──────────────┐───┐───────────────────────┐────
        /// result  :   a   a   a   a │ b │ c   c   c   c   c   c │ nil 
        ///             ──────────────└───└───────────────────────└────
        /// ``` 
        @inlinable public 
        func first(where predicate:(Value) throws -> Bool) rethrows -> Index?
        {
            guard var current:Index = self.head?.index
            else 
            {
                return nil
            }

            if try predicate(self.forest[current].value)
            {
                return current 
            }

            var bound:Index? = nil 
            // ascend
            while let parent:Index = self.forest.parent(of: current)
            {
                if try predicate(self.forest[parent].value) 
                {
                    // because ascension can skip elements, we don’t 
                    // know if this is the *first* element where `predicate`
                    // would have returned true, so we need to check the 
                    // right subtree of the child.
                    if let right:Index = self.forest.right(of: current) 
                    {
                        current = right 
                        bound = parent 
                        break 
                    }
                    else 
                    {
                        return parent 
                    }
                }
                else 
                {
                    current = parent 
                }
            }
            // descend
            while true 
            {
                if try predicate(self.forest[current].value) 
                {
                    bound = current 
                    guard let left:Index = self.forest.left(of: current) 
                    else 
                    {
                        break 
                    }
                    current = left
                }
                else if let right:Index = self.forest.right(of: current)
                {
                    current = right
                }
                else 
                {
                    break 
                }
            }
            return bound 
        }
    }
}
extension Forest 
{
    // @inlinable public 
    // func first(bisecting root:Index, where predicate:(Value) throws -> Bool) rethrows -> Index?
    // {
    //     if try predicate(self[root].value)
    //     {
    //         if let next:Index = self.left(of: root) 
    //         {
    //             return try self.first(bisecting: next, where: predicate) ?? root
    //         }
    //         else 
    //         {
    //             return root 
    //         }
    //     }
    //     else if let next:Index = self.right(of: root)
    //     {
    //         return try self.first(bisecting: next, where: predicate)
    //     }
    //     else 
    //     {
    //         return nil
    //     }
    // }
}
extension Forest.Tree 
{
    /// Performs binary search on this tree, returning a valid leaf node 
    /// for insertion if an exact match was not found.
    /// 
    /// This method is like ``first(where:)``, but it returns a leaf node 
    /// instead of a nearby internal node if an exact match is not found.
    /// 
    /// For point-like data, performing insertion with this method may be 
    /// more efficient than calling ``first(where:)`` and walking back down 
    /// from an internal node.
    @inlinable public 
    func walk(by less:(Value) throws -> Bool?) rethrows -> (index:Forest.Index, side:Forest.Node.Side?)?
    {
        guard var current:Forest.Index = self.head?.index
        else 
        {
            return nil
        }

        switch try less(self.forest[current].value)
        {
        case false?:
            // head can never have a left-child. we return `nil` and not `(current, .left)`
            // to reflect the fact that any such insertion would also change ``head``.
            return nil 
        case nil: 
            return (current, nil) 
        case true?: 
            break 
        }
        ascending:
        while let parent:Forest.Index = self.forest.parent(of: current)
        {
            switch try less(self.forest[parent].value) 
            {
            case false?: 
                break ascending 
            case nil: 
                return (parent, nil) 
            case true?:
                current = parent 
            }
        }
        guard var current:Forest.Index = self.forest.right(of: current)
        else 
        {
            return (current, .right)
        }
        // descend 
        while true
        {
            switch try less(self.forest[current].value)
            {
            case true?:
                if let next:Forest.Index = self.forest.right(of: current)
                {
                    current = next
                }
                else
                {
                    return (current, .right)
                }
            
            case nil: 
                return (current, nil) 
            
            case false?:
                if let next:Forest.Index = self.forest.left(of: current)
                {
                    current = next
                }
                else
                {
                    return (current, .left)
                }
            }
        }
    }
}
extension Forest.Tree where Value:Comparable 
{
    @inlinable public 
    func find(_ value:Value) -> Forest<Value>.Index?
    {
        self.first(where: { value <= $0 }).flatMap { self.forest[$0].value == value ? $0 : nil }
    }
}
extension Forest.Tree:CustomStringConvertible 
{
    public 
    var description:String
    {
       self.head.map 
       {
            self.forest.description(head: $0, 
                root: self.forest.root(of: $0.index))
       } ?? "nil"
    }
}