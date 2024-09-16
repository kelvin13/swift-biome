@frozen public
struct Version:Hashable, Sendable
{
    /// A reference to a ``/Biome//Branch`` within a ``/Biome//Tree``.
    @frozen public
    struct Branch:Hashable, Strideable, Sendable 
    {
        public
        let offset:UInt16 

        @inlinable public
        init(_ offset:UInt16)
        {
            self.offset = offset
        }
        
        @inlinable public static 
        func < (lhs:Self, rhs:Self) -> Bool
        {
            lhs.offset < rhs.offset
        }
        @inlinable public
        func advanced(by stride:Int) -> Self 
        {
            .init(self.offset.advanced(by: stride))
        }
        @inlinable public
        func distance(to other:Self) -> Int
        {
            self.offset.distance(to: other.offset)
        }
    }
    /// A reference to a ``/Biome//Revision`` within a ``/Biome//Branch``. 
    /// 
    /// Revision numbers always start from 0, even when a branch was forked from 
    /// another branch. This makes it possible to tell if a revision has a 
    /// branch-local predecessor without needing any external information.
    @frozen public
    struct Revision:Hashable, Strideable, Sendable
    {
        public
        let offset:UInt16 

        public static 
        let max:Self = .init(.max)

        @inlinable public
        init(_ offset:UInt16)
        {
            self.offset = offset
        }

        @inlinable public static 
        func < (lhs:Self, rhs:Self) -> Bool
        {
            lhs.offset < rhs.offset
        }
        @inlinable public
        func advanced(by stride:Int) -> Self 
        {
            .init(self.offset.advanced(by: stride))
        }
        @inlinable public
        func distance(to other:Self) -> Int
        {
            self.offset.distance(to: other.offset)
        }

        @inlinable public
        var predecessor:Self? 
        {
            self.offset < 1 ? nil : .init(self.offset - 1)
        }
    }

    public
    var branch:Branch
    public
    var revision:Revision

    @inlinable public
    init(_ branch:Branch, _ revision:Revision)
    {
        self.branch = branch 
        self.revision = revision 
    }
}
