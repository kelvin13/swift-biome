protocol PeriodAxis<Divergence>
{
    associatedtype Divergence:BranchDivergence

    subscript<Value>(field:FieldAccessor<Divergence, Value>) -> PeriodHead<Value>
    {
        get
    }
}
