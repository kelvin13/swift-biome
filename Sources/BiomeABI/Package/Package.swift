/// A globally-unique number referencing a package.
@frozen public 
struct Package:Hashable, Comparable, Strideable, Sendable 
{
    public
    let offset:UInt16
    
    @inlinable public
    init(offset:UInt16)
    {
        self.offset = offset
    }

    @inlinable public
    func advanced(by stride:Int) -> Self 
    {
        .init(offset: self.offset.advanced(by: stride))
    }
    @inlinable public
    func distance(to other:Self) -> Int
    {
        self.offset.distance(to: other.offset)
    }
    @inlinable public static 
    func < (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.offset < rhs.offset
    }

    public static 
    let swift:Self = .init(offset: 0)
    public static 
    let core:Self = .init(offset: 1) 

    @inlinable public
    var isCommunityPackage:Bool
    {
        self.offset > 1
    }
}
