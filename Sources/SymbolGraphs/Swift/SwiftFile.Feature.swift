extension SwiftFile 
{
    @frozen public 
    struct Feature:Sendable, Equatable
    {
        public 
        let line:Int
        public
        let character:Int
        public
        let vertex:Int 
    }
}
extension SwiftFile.Feature:Comparable
{
    @inlinable public static 
    func < (lhs:Self, rhs:Self) -> Bool 
    {
        (lhs.line, lhs.character, lhs.vertex) < (rhs.line, rhs.character, rhs.vertex)
    }
}