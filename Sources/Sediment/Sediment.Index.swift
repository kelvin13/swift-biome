extension Sediment
{
    @frozen public 
    struct Index:Hashable, Strideable, CustomStringConvertible, Sendable 
    {
        public 
        let bits:UInt32 
        
        @inlinable public
        var offset:Int
        {
            .init(self.bits)
        }
        
        @inlinable public static 
        func < (lhs:Self, rhs:Self) -> Bool 
        {
            lhs.bits < rhs.bits 
        }
        @inlinable public
        func advanced(by stride:UInt32.Stride) -> Self 
        {
            .init(bits: self.bits.advanced(by: stride))
        }
        @inlinable public
        func distance(to other:Self) -> UInt32.Stride
        {
            self.bits.distance(to: other.bits)
        }
        
        @inlinable public
        init(offset:Int)
        {
            self.init(bits: .init(offset))
        }
        @inlinable public
        init(bits:UInt32)
        {
            self.bits = bits
        }

        public 
        var description:String 
        {
            self.bits.description
        }
    }
}