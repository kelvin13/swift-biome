struct OverlayTable:Sendable
{
    var divergences:[Diacritic: Overlay]

    init()
    {
        self.divergences = [:]
    }
}
extension OverlayTable
{
    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.divergences.revert(to: rollbacks)
    }
}
extension OverlayTable:PeriodAxis
{
    subscript<Value>(field:FieldAccessor<Overlay, Value>) -> PeriodHead<Value>
    {
        .alternate(self.divergences[field.key]?[keyPath: field.alternate])
    }
}
extension OverlayTable:BranchAxis
{
    subscript<Value>(field:FieldAccessor<Overlay, Value>) -> OriginalHead<Value>?
    {
        _read
        {
            yield self.divergences[field.key]?[keyPath: field.alternate]?.head
        }
    }
    subscript<Value>(field:FieldAccessor<Overlay, Value>, 
        since revision:Version.Revision) -> OriginalHead<Value>?
    {
        _read
        {
            yield self[field]
        }
        _modify
        {
            yield &self.divergences[field.key, default: .init()][keyPath: field.alternate][since: revision]
        }
    }
}
