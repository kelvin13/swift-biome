extension Route 
{
    struct Stems 
    {
        private 
        var counter:Stem
        private
        var table:[CaselessString: Stem]
        private 
        var free:[Stem]
        
        var _count:Int 
        {
            self.table.count 
        }
        var _memoryFootprint:Int 
        {
            let direct:Int = self.table.capacity * 
                MemoryLayout<Dictionary<CaselessString, Stem>.Element>.stride
            let indirect:Int = self.table.keys.reduce(0) { $0 + $1.lowercased.utf8.count }
            return direct + indirect
        }
        
        init() 
        {
            self.counter = .init()
            self.table = [:]
            self.free = []
        }
    }
}
extension CaselessString
{
    fileprivate 
    init<Component>(_ components:some Sequence<Component>)
        where Component:StringProtocol 
    {
        self.init(lowercased: components.map { $0.lowercased() }.joined(separator: "\u{0}"))
    }
}
extension Route.Stems 
{
    private mutating 
    func register(_ string:CaselessString) -> Route.Stem 
    {
        { $0 }(&self.table[string, default: self.free.popLast() ?? self.counter.increment()])
    }
    mutating 
    func register<Component>(components:some Sequence<Component>) -> Route.Stem 
        where Component:StringProtocol 
    {
        self.register(.init(components))
    }
    mutating 
    func register(component:some StringProtocol) -> Route.Stem 
    {
        self.register(.init(component))
    }
}
        
extension Route.Stems 
{
    private 
    subscript(subpath:CaselessString) -> Route.Stem? 
    {
        self.table[subpath]
    }
    
    // https://github.com/apple/swift/issues/61387
    subscript<Component>(leaf component:Component) -> Route.Stem? 
        where Component:StringProtocol
    {
        self.table[.init(component)]
    }
    private 
    subscript<Component>(stem components:some Sequence<Component>) -> Route.Stem? 
        where Component:StringProtocol
    {
        self.table[.init(components)]
    }
}
extension Route.Stems
{
    private 
    subscript(leaf component:_SymbolLink.Component) -> Route.Stem? 
    {
        if let hyphen:String.Index = component.hyphen 
        {
            return self[leaf: component.string[..<hyphen]]
        }
        else 
        {
            return self[leaf: component.string]
        }
    }

    subscript<Component>(namespace:Module, 
        straight infix:some BidirectionalCollection<Component>) -> Route? 
        where Component:StringProtocol
    {
        if  let leaf:Component = infix.last,
            let leaf:Route.Stem = self[leaf: leaf],
            let stem:Route.Stem = self[stem: infix.dropLast()]
        {
            return .init(namespace, stem, leaf, orientation: .straight)
        }
        else 
        {
            return nil
        }
    }
    subscript<Component>(namespace:Module, 
        infix:some BidirectionalCollection<Component>, 
        suffix:_SymbolLink) -> Route? 
        where Component:StringProtocol
    {
        guard let leaf:Route.Stem = self[leaf: suffix.path.last]
        else 
        {
            return nil 
        }
        let slice:_SymbolLink.SubSequence = suffix.dropLast()
        let stem:Route.Stem? 
        if  slice.isEmpty
        {
            stem = self[stem: infix]
        }
        else if infix.isEmpty
        {
            stem = self[stem: slice]
        }
        else 
        {
            stem = self[stem: infix.map(String.init(_:)) + slice]
        }
        return stem.map 
        {
            .init(namespace, $0, leaf, orientation: suffix.path.orientation)
        }
    }
    subscript(namespace:Module, suffix:_SymbolLink) -> Route? 
    {
        self[namespace, EmptyCollection<String>.init(), suffix]
    }
}