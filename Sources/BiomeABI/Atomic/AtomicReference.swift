public
protocol AtomicReference:Hashable
{
    // needs to be a requirement, to prevent infinite recursion on ``Module``.
    var nationality:Package { get }
    var culture:Module { get }
}
extension AtomicReference
{
    @inlinable public
    var nationality:Package
    {
        self.culture.nationality
    }
}
