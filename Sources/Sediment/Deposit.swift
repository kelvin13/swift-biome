// extension Sediment where Value:Equatable
// {
//     /// Deposits the given value if it is not equivalent to the existing value.
//     @inlinable public mutating 
//     func deposit(_ head:inout Head?, inserting value:__owned Value, time:Instant) 
//     {
//         head = self.deposit(inserting: value, time: time, over: head)
//     }
//     /// Deposits the given value if it is not equivalent to the existing value.
//     ///
//     /// -   Returns: 
//     ///     The `head` parameter unchanged, if it is not [`nil`]() *and* its value 
//     ///     equals the `value` parameter, otherwise a new head.
//     @inlinable public mutating 
//     func deposit(inserting value:__owned Value, time:Instant, over head:Head?) -> Head
//     {
//         guard let top:Head = head
//         else 
//         {
//             return self.deposit(value, time: time)
//         }
//         if self[top.index].value != value 
//         {
//             return self.deposit(value, time: time, over: top)
//         }
//         else 
//         {
//             return top
//         }
//     }
// }
extension Sediment
{
    /// Deposits a value to this sedimentary buffer. The timestamp must 
    /// be equal to or greater than that of any existing element in the buffer.
    @inlinable public mutating
    func deposit(_ value:__owned Value, time:__owned Instant, 
        over head:Head?) -> Head
    {
        if let head:Head 
        {
            return self.deposit(value, time: time, over: head)
        }
        else 
        {
            return self.deposit(value, time: time)
        }
    }
    @inlinable public mutating
    func deposit(_ value:__owned Value, time:__owned Instant, 
        over head:Head) -> Head
    {
        let new:Index = self.append(value, since: time, color: .red, parent: head.index)
        self.attach(new, on: .right, of: head.index)
        return .init(new)
    }
    @inlinable public mutating 
    func deposit(_ value:__owned Value, time:__owned Instant) -> Head  
    {
        return .init(self.append(value, since: time, color: .black))
    }
}
extension Sediment
{
    /// Attaches the bed at the given index to the specified parent bed, rebalancing 
    /// the sediment as needed. The referenced bed is assumed to already have its 
    /// ``Bed/.parent`` field set to `parent`.
    @inlinable public mutating 
    func attach(_ index:Index, on side:Bed.Side, of parent:Index) 
    {
        assert(self[parent][side] == parent)

        self[parent][side] = index 
        self.balance(insertion: index, on: side, of: parent)
    }

    @inlinable public mutating 
    func balance(insertion:Index, on side:Bed.Side?, of parent:Index)
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
