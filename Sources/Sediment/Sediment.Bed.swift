extension Sediment.Bed:Sendable where Instant:Sendable, Value:Sendable {}
extension Sediment
{
    @frozen public 
    struct Bed 
    {
        public 
        var value:Value
        public 
        var since:Instant
        public 
        var color:Color
        public 
        var left:Index 
        public 
        var right:Index 
        public 
        var parent:Index

        @inlinable public 
        init(_ value:Value, since time:Instant, color:Color, index:Index, parent:Index?)
        {
            self.value = value 
            self.color = color
            self.since = time
            self.left = index 
            self.right = index 
            self.parent = parent ?? index 
        }
    }
}
extension Sediment.Bed
{
    @frozen public 
    enum Color:Sendable
    {
        case red
        case black
    }
}
extension Sediment.Bed
{
    @frozen public 
    enum Side:Sendable
    {
        case left
        case right 

        @inlinable public 
        var other:Self 
        {
            switch self 
            {
            case .left: return .right
            case .right: return .left
            }
        }
        @inlinable public 
        var left:Bool 
        {
            switch self 
            {
            case .left:     return true
            case .right:    return false
            }
        }
        @inlinable public 
        var right:Bool 
        {
            switch self 
            {
            case .left:     return false
            case .right:    return true
            }
        }
    }

    @inlinable public 
    subscript(child:Side) -> Sediment<Instant, Value>.Index 
    {
        _read 
        {
            switch child 
            {
            case .left:     yield  self.left 
            case .right:    yield  self.right 
            }
        }
        _modify 
        {
            switch child 
            {
            case .left:     yield &self.left 
            case .right:    yield &self.right 
            }
        }
    }
}
extension Sediment.Bed:CustomStringConvertible
{
    public 
    var description:String 
    {
        switch self.color 
        {
        case .red:
            return "[\(self.parent)][\(self.left), \(self.right)] red(\(self.value))"
        case .black:
            return "[\(self.parent)][\(self.left), \(self.right)] black(\(self.value))"
        }
    }
}