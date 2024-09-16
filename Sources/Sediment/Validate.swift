extension Sediment 
{
    // verifies that all paths in `node`’s subtree have the same black height,
    // and that `node` and all of its children satisfy the red property.
    public 
    func blacks(under root:Index?) -> Int?
    {
        guard let root:Index
        else
        {
            return 1
        }
        if case .red = self[root].color
        {
            if case .red? = self.left(of: root).map({ self[$0].color })
            {
                return nil 
            }
            if case .red? = self.right(of: root).map({ self[$0].color })
            {
                return nil 
            }
        }
        guard   let blacks:Int = self.blacks(under: self.left(of: root)),
                case blacks? = self.blacks(under: self.right(of: root))
        else
        {
            return nil
        }
        switch self[root].color 
        {
        case .black: 
            return blacks + 1 
        case .red: 
            return blacks 
        }
    }
}
extension Sediment.Stratum
{
    // verifies that all paths in the red-black tree have the same black height,
    // that all nodes satisfy the red property, and that the root is black
    public 
    func validate() -> Bool
    {
        guard let root:Sediment<Instant, Value>.Index = 
            (self.head?.index).map(self.sediment.root(of:))
        else 
        {
            return true 
        }
        if  case .black = self.sediment[root].color, 
            case _? = self.sediment.blacks(under: root)
        {
            return true 
        }
        else 
        {
            return false 
        }
    }
}