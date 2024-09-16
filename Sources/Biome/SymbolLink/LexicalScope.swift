struct LexicalScope 
{
    let namespace:Module
    let path:[String]

    init(_ namespace:Module, _ path:[String] = [])
    {
        self.namespace = namespace 
        self.path = path
    }
    init(_ symbol:__shared Symbol.Intrinsic)
    {
        switch symbol.orientation 
        {
        case .gay:
            self.init(symbol.namespace,       symbol.path.prefix)
        case .straight:
            self.init(symbol.namespace, .init(symbol.path))
        }
    }

    func scan<T>(concatenating link:_SymbolLink, stems:Route.Stems, 
        until match:(Route) throws -> T?) rethrows -> T?
    {
        for level:Int in self.path.indices.reversed()
        {
            if  let key:Route = 
                    stems[self.namespace, self.path.prefix(through: level), link],
                let match:T = try match(key)
            {
                return match
            }
        }
        return try stems[self.namespace, link].flatMap(match)
    }
}