protocol FascesView:RandomAccessCollection 
{
    var base:Fasces { get }
}
extension FascesView
{
    var startIndex:Int 
    {
        self.base.startIndex
    }
    var endIndex:Int 
    {
        self.base.endIndex
    }
}

extension Fasces
{
    struct Modules:FascesView
    {
        let base:Fasces
    }
    struct Articles:FascesView
    {
        let base:Fasces
    }
    struct Symbols:FascesView
    {
        let base:Fasces
    }
    struct Overlays:FascesView
    {
        let base:Fasces
    }

    struct Routes:FascesView
    {
        let base:Fasces
    }
    struct AugmentedRoutes
    {
        private 
        let trunk:Routes, 
            routes:RoutingTable, 
            branch:Version.Branch

        init(_ trunk:Routes, _ routes:RoutingTable, branch:Version.Branch)
        {
            self.trunk = trunk 
            self.routes = routes
            self.branch = branch
        }
    }

    var modules:Modules
    {
        .init(base: self)
    }
    var articles:Articles
    {
        .init(base: self)
    }
    var symbols:Symbols
    {
        .init(base: self)
    }
    var overlays:Overlays
    {
        .init(base: self)
    }

    var routes:Routes
    {
        .init(base: self)
    }
    func routes(layering routes:RoutingTable, branch:Version.Branch) -> AugmentedRoutes 
    {
        .init(self.routes, routes, branch: branch)
    }
}
extension Fasces.Modules:Periods
{
    subscript(index:Int) -> Period<IntrinsicSlice<Module>>
    {
        self.base[index].modules
    }
}
extension Fasces.Articles:Periods
{
    subscript(index:Int) -> Period<IntrinsicSlice<Article>>
    {
        self.base[index].articles
    }
}
extension Fasces.Symbols:Periods
{
    subscript(index:Int) -> Period<IntrinsicSlice<Symbol>>
    {
        self.base[index].symbols
    }
}
extension Fasces.Overlays:Periods
{
    subscript(index:Int) -> Period<OverlayTable>
    {
        self.base[index].overlays
    }
}

extension Fasces.Routes
{
    subscript(index:Int) -> Period<RoutingTable>
    {
        self.base[index].routes
    }
}
extension Fasces.AugmentedRoutes
{
    func select<T>(_ route:Route, 
        where filter:(Composite, Version.Branch) throws -> T?) rethrows -> Selection<T>?
    {
        var selection:Selection<T>? = nil
        try self.query(route)
        {
            if let selected:T = try filter($0, $1)
            {
                selection.append(selected)
            }
        }
        return selection
    }
    private 
    func query(_ route:Route, 
        _ body:(Composite, Version.Branch) throws -> ()) rethrows 
    {
        try self.routes.query(route)
        { 
            try body($0, self.branch) 
        }
        try self.trunk.query(route, body)
    }
}
