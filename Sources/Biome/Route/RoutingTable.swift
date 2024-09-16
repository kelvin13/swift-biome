struct RoutingTable
{
    private
    var table:[Route: Stack]

    init()
    {
        self.table = [:]
    }
}

extension RoutingTable
{
    mutating 
    func stack(routes:some Sequence<(Route, Composite)>, revision:Version.Revision) 
    {
        for (route, composite):(Route, Composite) in routes 
        {
            self.table[route].insert(composite, revision: revision)
        }
    }
    func query(_ route:Route, _ body:(Composite) throws -> ()) rethrows 
    {
        try self.query(route) { (composite:Composite, _) in try body(composite) }
    }
    func query(_ route:Route, _ body:(Composite, Version.Revision) throws -> ()) rethrows 
    {
        try self.table[route]?.forEach(body)
    }

    mutating 
    func revert(to revision:Version.Revision)
    {
        self.table = self.table.compactMapValues
        {
            $0.reverted(to: revision)
        }
    }
}