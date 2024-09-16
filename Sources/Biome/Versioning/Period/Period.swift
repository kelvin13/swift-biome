import Sediment

struct Period<Axis>
{
    let axis:Axis
    /// The last version contained within this period.
    let latest:Version
    /// The branch and revision this period was forked from, 
    /// if applicable.
    let fork:Version?

    init(_ axis:Axis, latest:Version, fork:Version?)
    {
        self.axis = axis 
        self.latest = latest 
        self.fork = fork
    }
}
extension Period
{
    /// The index of the original branch this period was cut from.
    /// 
    /// This is the branch that contains the period, not the branch 
    /// the period was forked from.
    var branch:Version.Branch
    {
        self.latest.branch
    }
}
extension Period<RoutingTable>
{
    func query(_ key:Route, _ body:(Composite) throws -> ()) rethrows 
    {
        try self.axis.query(key)
        {
            if $1 <= self.latest.revision 
            {
                try body($0)
            }
        }
    }
}
extension Sequence<Period<RoutingTable>>
{
    func select(_ key:Route) -> Selection<Composite>?
    {
        self.select(key) { $0 }
    }
    func select(_ key:Route, where predicate:(Composite) throws -> Bool) rethrows 
        -> Selection<Composite>?
    {
        try self.select(key) { try predicate($0) ? $0 : nil }
    }
    private
    func select<T>(_ key:Route, where filter:(Composite) throws -> T?) rethrows 
        -> Selection<T>?
    {
        var selection:Selection<T>? = nil
        try self.query(key) 
        {
            if let selected:T = try filter($0)
            {
                selection.append(selected)
            }
        }
        return selection
    }

    func query(_ key:Route, _ body:(Composite) throws -> ()) rethrows 
    {
        for period:Period<RoutingTable> in self
        {
            try period.query(key, body)
        }
    }
    func query(_ key:Route, _ body:(Composite, Version.Branch) throws -> ()) rethrows 
    {
        for period:Period<RoutingTable> in self
        {
            try period.query(key) { try body($0, period.branch) }
        }
    }
}

extension Period where Axis:PeriodAxis
{
    struct FieldView<Value> where Value:Equatable
    {
        let sediment:Sediment<Version.Revision, Value>
        let period:Period<Axis>

        init(_ period:Period<Axis>, sediment:Sediment<Version.Revision, Value>)
        {
            self.sediment = sediment
            self.period = period
        }
    }
}
extension Period.FieldView
{
    var axis:Axis
    {
        self.period.axis
    }
    var fork:Version?
    {
        self.period.fork
    }
    var latest:Version
    {
        self.period.latest
    }
}
