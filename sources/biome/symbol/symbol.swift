struct Symbol:Sendable, Identifiable, CustomStringConvertible  
{
    /// A globally-unique index referencing a symbol. 
    /// 
    /// A symbol index encodes the module it belongs to, which makes it possible 
    /// to query module membership based on the index alone.
    struct Index:CulturalIndex, Hashable, Sendable
    {
        let module:Module.Index
        let bits:UInt32
        
        var offset:Int
        {
            .init(self.bits)
        }
        
        init(_ module:Module.Index, offset:Int)
        {
            self.init(module, bits: .init(offset))
        }
        fileprivate 
        init(_ module:Module.Index, bits:UInt32)
        {
            self.module = module
            self.bits = bits
        }
    }
    struct IndexRange:RandomAccessCollection, Hashable, Sendable
    {
        let module:Module.Index 
        let bits:Range<UInt32>
        
        var offsets:Range<Int> 
        {
            .init(self.bits.lowerBound) ..< .init(self.bits.upperBound)
        }
        var lowerBound:Symbol.Index 
        {
            .init(self.module, bits: self.bits.lowerBound)
        }
        var upperBound:Symbol.Index 
        {
            .init(self.module, bits: self.bits.upperBound)
        }
        
        var startIndex:UInt32
        {
            self.bits.startIndex
        }
        var endIndex:UInt32
        {
            self.bits.endIndex
        }
        subscript(index:UInt32) -> Symbol.Index 
        {
            .init(self.module, bits: self.bits[index])
        }
        
        init(_ module:Module.Index, offsets:Range<Int>)
        {
            self.init(module, bits: .init(offsets.lowerBound) ..< .init(offsets.upperBound))
        }
        init(_ module:Module.Index, bits:Range<UInt32>)
        {
            self.module = module
            self.bits = bits
        }
    }
    // this is like ``Symbol.IndexRange``, except the ``module`` field refers to 
    // a namespace, not the module that actually contains the symbol
    struct ColonialRange:Hashable, Sendable
    {
        let namespace:Module.Index 
        let bits:Range<UInt32>
        
        var offsets:Range<Int> 
        {
            .init(self.bits.lowerBound) ..< .init(self.bits.upperBound)
        }
        
        init(namespace:Module.Index, offsets:Range<Int>)
        {
            self.init(namespace: namespace, bits: .init(offsets.lowerBound) ..< .init(offsets.upperBound))
        }
        private 
        init(namespace:Module.Index, bits:Range<UInt32>)
        {
            self.namespace = namespace
            self.bits = bits
        }
    }
    
    struct Heads 
    {
        @Keyframe<Declaration>.Head
        var declaration:Keyframe<Declaration>.Buffer.Index?
        @Keyframe<Relationships>.Head
        var relationships:Keyframe<Relationships>.Buffer.Index?
        @Keyframe<Documentation>.Head
        var documentation:Keyframe<Documentation>.Buffer.Index?
        
        init() 
        {
            self._declaration = .init()
            self._relationships = .init()
            self._documentation = .init()
        }
    }
    
    struct Nest 
    {
        let namespace:Module.Index 
        let prefix:[String]
    }
    
    // these stored properties are constant with respect to symbol identity. 
    let id:ID
    //  TODO: see if small-array optimizations here are beneficial, since this could 
    //  often be a single-element array
    let path:Path
    let color:Color
    let route:Route
    
    var heads:Heads
    var _opinions:[Package.Index: Traits]
    
    var name:String 
    {
        self.path.last
    }
    //  this is only the same as the perpetrator if this symbol is part of its 
    //  core symbol graph.
    var namespace:Module.Index 
    {
        self.route.namespace
    }
    var nest:Nest?
    {
        self.path.prefix.isEmpty ? 
            nil : .init(namespace: self.namespace, prefix: self.path.prefix)
    }
    var orientation:Route.Orientation
    {
        self.color.orientation
    }
    var description:String 
    {
        self.path.joined(separator: ".")
    }
    
    init(id:ID, path:Path, color:Color, route:Route)
    {
        self.id = id 
        self.path = path
        self.color = color 
        self.route = route
        
        self.heads = .init()
        self._opinions = [:]
    }
    
    mutating 
    func update(traits:[Trait], from package:Package.Index)  
    {
        self._opinions[package, default: .init()].update(with: traits, as: self.color)
    }
}
