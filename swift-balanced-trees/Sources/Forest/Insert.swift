extension Forest where Value:Comparable 
{
    @discardableResult
    @inlinable public mutating
    func insert(_ value:Value, into tree:inout Tree.Head?) -> Index 
    {
        self.insert(value, into: &tree, order: < )
    }
}
extension Forest 
{
    @available(*, deprecated, message: "use one of insert(_:before:) or insert(_:)")
    @inlinable public mutating
    func push(min value:Value, into tree:inout Tree.Head?) 
    {
        if let head:Tree.Head = tree
        {
            tree = .init(self.insert(value, on: .left, of: head.index))
        }
        else 
        {
            tree = .some(self.insert(root: value))
        }
    }
    @discardableResult
    @inlinable public mutating
    func insert(_ value:__owned Value, into tree:inout Tree.Head?,
        order ascending:(Value, Value) throws -> Bool) rethrows -> Index
    {
        switch try self[tree].walk(by: { try ascending($0, value) })
        {
        case nil:
            // node would become the new head. 
            if var head:Tree.Head = tree 
            {
                head.index = self.insert(value, on: .left, of: head.index)
                tree = head 
                return head.index 
            }
            else 
            {
                let head:Tree.Head = self.insert(value)
                tree = head 
                return head.index 
            }
        
        case (let parent, let side?)?:
            return self.insert(value, on: side, of: parent)
        
        case (let occupant, nil)?:
            return occupant
        }
    }

    @inlinable public mutating
    func insert(_ value:__owned Value, before head:Tree.Head) -> Tree.Head
    {
        .init(self.insert(value, on: .left, of: head.index))
    }
    @inlinable public mutating 
    func insert(_ value:__owned Value) -> Tree.Head  
    {
        let index:Index = self.endIndex
        self.nodes.append(.init(.black(value), at: index))
        return .init(index)
    }
    @available(*, deprecated, renamed: "insert(_:)")
    @inlinable public mutating 
    func insert(root value:Value) -> Tree.Head  
    {
        self.insert(value)
    }

    @inlinable public mutating 
    func insert(_ value:__owned Value, on side:Node.Side, of parent:Index) -> Index
    {
        assert(self[parent][side] == parent)

        let index:Index = self.endIndex
        self.nodes.append(.init(.red(value), at: index, parent: parent))
        self[parent][side] = index 
        self.balance(insertion: index, on: side, of: parent)
        return index 
    }

    @inlinable public mutating 
    func balance(insertion:Index, on side:Node.Side?, of parent:Index)
    {
        guard case .red = self[parent].color
        else 
        {
            // case 2: the node’s parent is black. the tree is already valid
            return
        }
        // from here on out, the node *must* have a grandparent because its
        // parent is red which means it cannot be the root
        let grandparent:Index = self[parent].parent
        let right:Index? = self.right(of: grandparent)
        let left:Index? = self.left(of: grandparent)

        switch  (left, right) 
        {
        case    (parent?, let uncle?),
                (let uncle?, parent?):
            guard case .red = self[uncle].color 
            else 
            {
                break 
            }
            // case 3: both the parent and the uncle are red. repaint both of them
            //         black and make the grandparent red. fix the grandparent.
            self[parent].color = .black
            self[uncle].color = .black

            self[grandparent].color = .red
            if let greatgrandparent:Index = self.parent(of: grandparent) 
            {
                // recursive call
                self.balance(insertion: grandparent, on: nil, of: greatgrandparent)
            }
            else 
            {
                // case 1: the node is the root. repaint the node black
                self[grandparent].color = .black
            }
            return

        default: 
            break 
        }

        // case 4: the node’s parent is red, its uncle is black, and the node is
        //         an inner child. perform a rotation on the node’s parent.
        //         then fallthrough to case 5.
        let pivot:Index
        if      case parent? = left, side?.right ?? (self[parent].right == insertion)
        {
            // inner child: is **right** child of parent, which is **left** child of grandparent.
            pivot = parent
            self.rotateLeft(parent, on: (.left, of: grandparent))
        }
        else if case parent? = right, side?.left ?? (self[parent].left == insertion)
        {
            // inner child: is **left** child of parent, which is **right** child of grandparent.
            pivot = parent
            self.rotateRight(parent, on: (.right, of: grandparent))
        }
        else
        {
            pivot = insertion
        }

        // case 5: the node’s (n)’s parent is red, its uncle is black, and the node
        //         is an outer child. rotate on the grandparent, which is known
        //         to be black, and switch its color with the former parent’s.

        // counterpart *always* exists!
        let counterpart:Index = self[pivot].parent

        self[counterpart].color = .black
        self[grandparent].color = .red
        // counterpart *always* has at least one child!
        if pivot == self[counterpart].left
        {
            self.rotateRight(grandparent)
        }
        else
        {
            self.rotateLeft(grandparent)
        }
    }
}