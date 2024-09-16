extension Sediment
{
    /// Removes all elements from this sedimentary buffer that were deposited after 
    /// the specified time, rebalancing the sediment as needed. 
    /// (Elements that were deposited *at* the given time are kept.)
    ///
    /// -   Returns: 
    ///     A rollback table, which can be used to rewind any externally-stored 
    ///     heads that may have been invalidated by this operation.
    ///
    /// Externally-stored indices referring to eroded elements will no longer be 
    /// valid after this operation. However indices referring to elements deposited 
    /// on or before the `until` argument will remain valid for subscripting 
    /// this collection.
    /// 
    /// This method does *not* shrink the underlying buffer allocation.
    @inlinable public mutating
    func erode(until time:Instant) -> Rollbacks
    {
        var uptree:[Index: Head?] = [:], 
            threshold:Index = self.endIndex
        while let head:Head = self.top
        {
            guard time < self[head.index].since
            else
            {
                break
            }

            uptree.updateValue(self.predecessor(of: head), forKey: head.index)
            threshold = head.index

            if let parent:Index = self.parent(of: head.index)
            {
                self.detach(head.index, from: (.right, of: parent))
            }
            else 
            {
                self.detach(head.index, from: nil)
            }
            self.beds.removeLast()
        }
        return .init(compressing: uptree, threshold: threshold)
    }
}
extension Sediment
{
    /// Detaches the bed at the specified index from its parent bed.
    /// This method does *not* deallocate the bed from the sediment.
    @inlinable public mutating 
    func detach(_ node:Index, from position:(side:Bed.Side, of:Index)?)
    {
        switch (self.left(of: node), self.right(of: node))
        {
        case (let a?, let b?):
            if case (left: let e, parent: let d)? = self.leftmost(of: b)
            {
                self.remove(sinking: node, on: position, a: a, b: b, d: d, e: e)
            }
            else 
            {
                self.remove(sinking: node, on: position, a: a, b: b)
            }
        
        case (let c?, nil), (nil, let c?):
            // an only-child must be red, and a red node cannot have a red parent. 
            assert(self[node].color == .black)
            assert(self[c].color == .red)
            self[c].color = .black
            self[position] = c
        
        case (nil, nil):
            switch (self[node].color, on: position)
            {
            case (.red, on: nil): 
                // a red node cannot be the root, so it must have a parent
                fatalError("unreachable")
            
            case (.red, on: (let side, of: let parent)?):
                // we can always delete a childless red node.
                self[side, of: parent] = nil
            
            case (.black, on: (let side, of: let parent)?):
                self[side, of: parent] = nil
                self.balance(removal: node, on: side, of: parent)
            
            case (.black, on: nil): 
                // we can always delete the root. 
                break 
            }
        }
    }
    @inlinable public mutating 
    func remove(sinking node:Index, on position:(side:Bed.Side, of:Index)?, 
        a:Index, b:Index, d:Index, e replacement:Index) 
    {
        //  there are up to 5 links that need to be updated, 
        //  which requires up to 11 memory writes. 
        //
        //  the additional write is because we must `nil`-out 
        //  the `node`’s left-child, since the replacement 
        //  will never have one.
        //
        //  note: (b) and (d) may be the same node. 
        //           ┆
        //         (node)
        //  ┌────────┴───────────────────────────┐
        // (a)                                  (b)
        //                              ┌────────┴───────┐
        //                             (d)
        //                      ┌───────┴───────┐
        //               (replacement)
        //                      └───┐
        //                         (c?)
        if case .red = self[replacement].color 
        {
            // if the destination is red, it will never have a child, 
            // because red nodes can only have 0 or 2 children.
            // we can always remove a red leaf node without needing to 
            // rebalance the tree.
            assert(self[replacement].right == replacement)
            self[replacement].color = self[node].color
            
            self[.left, of: d] = nil 
            self[.left, of: replacement] = a
            self[.right, of: replacement] = b
            self[position] = replacement
        }
        else if let c:Index = self.right(of: replacement)
        {
            // an only-child must be red 
            assert(self[c].color == .red)
            // (replacement) inherits the color of (node)
            self[replacement].color = self[node].color
            // (c) inherits the color of (node), which would have inherited 
            // the former color of (replacement), which was known to be black.
            // self[node] = .black
            self[c].color = .black

            self[.left, of: d] = c
            self[.left, of: replacement] = a 
            self[.right, of: replacement] = b 
            self[position] = replacement
        }
        else 
        {
            // (replacement) inherits the color of (node)
            self[replacement].color = self[node].color
            // self[node] = .black

            self[.left, of: d] = nil 
            self[.left, of: replacement] = a
            self[.right, of: replacement] = b
            self[position] = replacement
            self.balance(removal: node, on: .left, of: d)
        }
    }
    @inlinable public mutating 
    func remove(sinking node:Index, on position:(side:Bed.Side, of:Index)?, 
        a:Index, b replacement:Index) 
    {
        //  there are up to 4 links that need to be updated, 
        //  which requires up to 9 memory writes. 
        //
        //  the additional write is because we must `nil`-out 
        //  the `node`’s left-child, since the replacement 
        //  will never have one.
        //
        //           ┆
        //         (node)
        //  ┌────────┴───────────────────────────┐
        // (a)                             (replacement)
        //                                       └───────┐
        //                                              (c?)
        if case .red = self[replacement].color
        {
            // if the destination is red, it will never have a child, 
            // because red nodes can only have 0 or 2 children.
            // we can always remove a red leaf node without needing to 
            // rebalance the tree.
            assert(self[replacement].right == replacement)
            // a red node cannot have a red parent
            assert(self[node].color == .black)
            self[replacement].color = .black
            // we will delete (node) anyway, so we can skip the next 
            // two memory writes:
            // self[.right, of: replacement] = node
            // self[.left, of: node] = nil 
            self[.left, of: replacement] = a 
            self[.right, of: replacement] = nil 
            self[position] = replacement
        }
        else if let c:Index = self.right(of: replacement)
        {
            assert(self[c].color == .red)

            self[replacement].color = self[node].color
            self[c].color = .black

            // we will delete (node) anyway, so we can skip the next 
            // three memory writes:
            // self[.right, of: replacement] = node
            // self[.right, of: node] = c
            // self[.left, of: node] = nil
            self[.left, of: replacement] = a 
            self[.right, of: replacement] = c 
            self[position] = replacement
        }
        else 
        {
            // (replacement) inherits the color of (node)
            self[replacement].color = self[node].color
            // self[node] = .black
            // self[.right, of: replacement] = node 
            // self[.right, of: node] = nil
            // self[.left, of: node] = nil
            self[.left, of: replacement] = a 
            self[.right, of: replacement] = replacement
            self[position] = replacement
            self.balance(removal: node, on: .right, of: replacement)
        }
    }
    // note: this function must *not* assume (node) is still alive!
    @inlinable public mutating 
    func balance(removal node:Index, on side:Bed.Side, of parent:Index)
    {
        // by definition dead nodes are black. it’s possible for dead nodes 
        // to be marked red, since their state is uninitialized.
        // assert(self[node].color == .black)

        // the deleted node must have had a sibling, since if it did not, the sibling 
        // subtree would only have contributed +1 black height compared to the 
        // node’s subtree’s +2 black height.
        assert(self[parent][side.other] != parent)

        var sibling:Index = self[parent][side.other]
        // case 2: the node’s sibling is red. (the parent must be black.)
        //         make the parent red and the sibling black. rotate on the parent.
        //         fallthrough to cases 4–6.
        if case .red = self[sibling].color
        {
            // if the sibling is red, it must have two (black) children, 
            // because (node) is black.
            assert(self[sibling].left  != sibling)
            assert(self[sibling].right != sibling)
            assert(self[self[sibling].left].color  == .black)
            assert(self[self[sibling].right].color == .black)

            self[parent].color = .red
            self[sibling].color = .black
            switch side 
            {
            case .left:
                // new sibling will be the left child of the original sibling 
                sibling = self[sibling].left
                self.rotateLeft(parent)
            case .right:
                // new sibling will be the right child of the original sibling 
                sibling = self[sibling].right
                self.rotateRight(parent)
            }
            // note: rotations do not affect (node)’s relationship to (parent).
        }
        // case 3: the parent and sibling are both black. on the first iteration,
        //         the sibling has no children or else the black property would
        //         not have been held. however later, the sibling may have children
        //         which must both be black. repaint the sibling red, then fix the
        //         parent.
        else if case .black = self[parent].color,
                self.left(of: sibling).map({ self[$0].color == .black }) ?? true,
                self.right(of: sibling).map({ self[$0].color == .black }) ?? true
        {
            self[sibling].color = .red
            
            // recursive call
            if let grandparent:Index = self.parent(of: parent)
            {
                self.balance(removal: parent, 
                    on: self[grandparent].left == parent ? .left : .right, 
                    of: grandparent)
            }
            return
        }

        // from this point on, the sibling is assumed black because of case 2
        assert(self[sibling].color == .black)

        // case 4: the sibling is black, but the parent is red. repaint the sibling
        //         red and the parent black.
        if case .red = self[parent].color,
                self.left(of: sibling).map({ self[$0].color == .black }) ?? true,
                self.right(of: sibling).map({ self[$0].color == .black }) ?? true
        {
            self[sibling].color = .red
            self[parent].color = .black
            return
        }
        // from this point on, the sibling is assumed to have at least one red child
        // because of cases 2–4.
        // case 5: the sibling has one red inner child. (the parent’s color does
        //         not matter.) rotate on the sibling and switch its color and that
        //         of its child so that the new sibling has a red outer child.
        //         fallthrough to case 6.
        switch side 
        {
        case .left: 
            if self.right(of: sibling).map({ self[$0].color == .black }) ?? true
            {
                self[sibling].color = .red
                self[self[sibling].left].color = .black

                // update the sibling
                sibling = self.rotateRight(sibling)
            }
        case .right:
            if self.left(of: sibling).map({ self[$0].color == .black }) ?? true
            {
                self[sibling].color = .red
                self[self[sibling].right].color = .black

                // update the sibling
                sibling = rotateLeft(sibling)
            }
        }

        // case 6: the sibling has at least one red child on the outside. switch
        // the colors of the parent and the sibling, make the outer child black,
        // and rotate on the parent.
        self[sibling].color = self[parent].color
        self[parent].color = .black
        switch side 
        {
        case .left:
            self[self[sibling].right].color = .black
            self.rotateLeft(parent)

        case .right:
            self[self[sibling].left].color = .black
            self.rotateRight(parent)
        }
    }
}