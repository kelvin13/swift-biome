extension Route 
{
    struct Leaf:Hashable 
    {
        let bitPattern:UInt32 
        
        var stem:Stem 
        {
            .init(masking: self.bitPattern)
        }
        var outed:Self? 
        {
            let outed:Self = .init(bitPattern: self.stem.bitPattern)
            return outed == self ? nil : outed
        }
        var orientation:_SymbolLink.Orientation 
        {
            self.bitPattern & 1 == 0 ? .gay : .straight
        }
        
        init(_ stem:Stem, orientation:_SymbolLink.Orientation) 
        {
            switch orientation 
            {
            case .gay:      self.init(bitPattern: stem.bitPattern)
            case .straight: self.init(bitPattern: stem.bitPattern | 1)
            }
        }
        private 
        init(bitPattern:UInt32)
        {
            self.bitPattern = bitPattern
        }
    }
    // the lsb is reserved to encode orientation
    struct Stem:Hashable 
    {
        private(set)
        var bitPattern:UInt32
        
        init()
        {
            self.bitPattern = 0
        }
        init(masking bits:UInt32)
        {
            self.bitPattern = bits & 0xffff_fffe
        }
        
        mutating 
        func increment() -> Self
        {
            self.bitPattern += 2 
            return self 
        }
    }
}
