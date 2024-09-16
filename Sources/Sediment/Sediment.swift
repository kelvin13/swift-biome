extension Sediment:Sendable where Instant:Sendable, Value:Sendable {}

@frozen public 
struct Sediment<Instant, Value> where Instant:Comparable
{
    public 
    var beds:[Bed]

    @inlinable public 
    init() 
    {
        self.beds = []
    }

    /// Allocates a new bed at the top of the sedimentary buffer, and returns its index. 
    /// The new bed is not linked with any other bed.
    @inlinable public mutating 
    func append(_ value:__owned Value, since time:__owned Instant, 
        color:Bed.Color, 
        parent:Index? = nil) -> Index
    {
        let index:Index = self.endIndex
        self.beds.append(.init(value, since: time, color: color, index: index, parent: parent))
        return index
    }
    /// Returns the index of the topmost bed in this sediment, if this sediment is not empty.
    /// The top is always a head, if only deposition and erosion methods have been called
    /// on this sediment.
    @inlinable public 
    var top:Head?
    {
        self.indices.last.map(Head.init(_:))
    }
}
extension Sediment:RandomAccessCollection
{
    @inlinable public 
    var startIndex:Index 
    {
        .init(offset: self.beds.startIndex)
    }
    @inlinable public 
    var endIndex:Index 
    {
        .init(offset: self.beds.endIndex)
    }
    @inlinable public 
    subscript(index:Index) -> Bed 
    {
        _read 
        {
            yield  self.beds[index.offset]
        }
        _modify 
        {
            yield &self.beds[index.offset]
        }
    }
}
extension Sediment
{
    // “smart” subscripts, that update both ends of a link
    @inlinable public 
    subscript(side:Bed.Side, of parent:Index) -> Index
    {
        _read 
        {
            yield self[parent][side]
        }
        set(child)
        {
            self[child].parent = parent 
            self[parent][side] = child
        }
    }
    @inlinable public 
    subscript(side:Bed.Side, of parent:Index) -> Index?
    {
        _read 
        {
            yield self[side, of: parent] as Index 
        }
        set(child)
        {
            if let child:Index 
            {
                self[side, of: parent] = child 
            }
            else 
            {
                self[parent][side] = parent 
            }
        }
    }
    @inlinable public 
    subscript(position:(side:Bed.Side, of:Index)) -> Index
    {
        _read 
        {
            yield  self[position.side, of: position.of]
        }
        _modify
        {
            yield &self[position.side, of: position.of]
        }
    }
    @inlinable public 
    subscript(position:(side:Bed.Side, of:Index)) -> Index?
    {
        _read 
        {
            yield  self[position.side, of: position.of]
        }
        _modify
        {
            yield &self[position.side, of: position.of]
        }
    }
    @inlinable public 
    subscript(position:(side:Bed.Side, of:Index)?) -> Index?
    {
        get 
        {
            position.map { self[ $0] }
        }
        set(child)
        {
            if case (let side, of: let parent)? = position 
            {
                self[side, of: parent] = child ?? parent
            }
            else if let child:Index 
            {
                self[child].parent = child 
            }
        }
    }
}
extension Sediment
{
    /// Returns a new beds head, if the current head were to be deleted.
    @inlinable public 
    func predecessor(of head:Head) -> Head?
    {
        if let child:Index = self.left(of: head.index)
        {
            return .init(self.rightmost(from: child))
        }
        else 
        { 
            return self.parent(of: head.index).map(Head.init(_:))
        }
    }
    /// Returns the inorder predecessor of the node at the given index, in amortized O(1) time.
    @inlinable public 
    func predecessor(of index:Index) -> Index?
    {
        if let child:Index = self.left(of: index)
        {
            return self.rightmost(from: child)
        }

        var current:Index = index
        while   let parent:Index = self.parent(of: current),
                    current == self[parent].left
        {
            current = parent
        }
        return self.parent(of: current)
    }

    @available(*, unavailable, message: "head index can never have a successor")
    @inlinable public 
    func successor(of head:Head) -> Head?
    {
        nil
    }
    /// Returns the inorder successor of the node at the given index, in amortized O(1) time.
    @inlinable public 
    func successor(of index:Index) -> Index?
    {
        if let child:Index = self.right(of: index)
        {
            return self.leftmost(from: child)
        }

        var current:Index = index
        while   let parent:Index = self.parent(of: current), 
                    current == self[parent].right
        {
            current = parent
        }
        return self.parent(of: current)
    }
}
extension Sediment
{
    @inlinable public 
    func left(of index:Index) -> Index?
    {
        switch self[index].left 
        {
        case index:         return nil 
        case let left:      return left 
        }
    }
    @inlinable public 
    func right(of index:Index) -> Index?
    {
        switch self[index].right 
        {
        case index:         return nil 
        case let right:     return right 
        }
    }
    @inlinable public 
    func parent(of index:Index) -> Index?
    {
        switch self[index].parent 
        {
        case index:         return nil 
        case let parent:    return parent 
        }
    }

    @inlinable public 
    func leftmost(of index:Index) -> (left:Index, parent:Index)?
    {
        guard var current:Index = self.left(of: index)
        else 
        {
            return nil 
        }
        var previous:Index = index 
        while let next:Index = self.left(of: current)
        {
            previous = current  
            current = next 
        }
        return (left: current, parent: previous)
    }
    @inlinable public 
    func rightmost(of index:Index) -> (parent:Index, right:Index)?
    {
        guard var current:Index = self.right(of: index)
        else 
        {
            return nil 
        }
        var previous:Index = index 
        while let next:Index = self.right(of: current)
        {
            previous = current  
            current = next 
        }
        return (parent: previous, right: current)
    }

    @inlinable public 
    func leftmost(from index:Index) -> Index
    {
        var current:Index = index
        while let next:Index = self.left(of: current)
        {
            current = next 
        }
        return current
    }
    @inlinable public 
    func rightmost(from index:Index) -> Index
    {
        var current:Index = index
        while let next:Index = self.right(of: current)
        {
            current = next 
        }
        return current
    }
    @inlinable public 
    func root(of index:Index) -> Index
    {
        var current:Index = index
        while let next:Index = self.parent(of: current)
        {
            current = next 
        }
        return current
    }
}
extension Sediment 
{
    @discardableResult
    @inlinable public mutating 
    func rotateLeft(_ pivot:Index) -> Index
    {
        guard let parent:Index = self.parent(of: pivot)
        else 
        {
            return self.rotateLeft(pivot, on: nil)
        }
        if pivot == self[parent].left
        {
            return self.rotateLeft(pivot, on: (.left, of: parent))
        }
        else
        {
            return self.rotateLeft(pivot, on: (.right, of: parent))
        }
    }
    @discardableResult
    @inlinable public mutating 
    func rotateRight(_ pivot:Index) -> Index
    {
        guard let parent:Index = self.parent(of: pivot)
        else 
        {
            return self.rotateRight(pivot, on: nil)
        }
        if pivot == self[parent].left
        {
            return self.rotateRight(pivot, on: (.left, of: parent))
        }
        else
        {
            return self.rotateRight(pivot, on: (.right, of: parent))
        }
    }

    // performs a left rotation and returns the new vertex
    @discardableResult
    @inlinable public mutating 
    func rotateLeft(_ pivot:Index, on position:(side:Bed.Side, of:Index)?) -> Index
    {
        let vertex:Index = self[pivot].right
        if let left:Index = self.left(of: vertex)
        {
            self[left].parent = pivot 
            self[pivot].right = left
        }
        else 
        {
            self[pivot].right = pivot
        }
        if case let (side, parent)? = position
        {
            self[vertex].parent = parent 
            self[parent][side] = vertex 
        }
        else 
        {
            self[vertex].parent = vertex
        }
        self[vertex].left = pivot
        self[pivot].parent = vertex
        return vertex
    }
    // performs a right rotation and returns the new vertex
    @discardableResult
    @inlinable public mutating 
    func rotateRight(_ pivot:Index, on position:(side:Bed.Side, of:Index)?) -> Index
    {
        let vertex:Index = self[pivot].left
        if let right:Index = self.right(of: vertex) 
        {
            self[right].parent = pivot
            self[pivot].left = right
        }
        else 
        {
            self[pivot].left = pivot
        }
        if case let (side, parent)? = position
        {
            self[vertex].parent = parent 
            self[parent][side] = vertex 
        }
        else 
        {
            self[vertex].parent = vertex
        }
        self[vertex].right = pivot
        self[pivot].parent = vertex
        return vertex 
    }
}

extension Sediment:CustomStringConvertible
{
    public 
    var description:String 
    {
        self.description()
    }
    func description(head:Head? = nil, root:Index? = nil) -> String 
    {
        self.beds.isEmpty ? "[]" :
        """
        [
        \(zip(self.indices, self.beds).lazy.map 
        {
            (element:(index:Index, node:Bed)) -> String in 

            let value:String 
            switch element.index
            {
            case head?.index:
                value = "\(element.node) <- head"
            case root:
                value = "\(element.node) <- root"
            case _: 
                value = "\(element.node)"
            }
            return 
                """
                    [\(element.index)]: \(value)
                """
        }.joined(separator: "\n"))
        ]
        """
    }
}
