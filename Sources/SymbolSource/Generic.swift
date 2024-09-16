@frozen public 
struct Generic:Hashable, Sendable
{
    public
    var name:String 
    public
    var index:Int 
    public
    var depth:Int 

    @inlinable public 
    init(name:String, index:Int, depth:Int)
    {
        self.name = name 
        self.index = index 
        self.depth = depth
    }
}