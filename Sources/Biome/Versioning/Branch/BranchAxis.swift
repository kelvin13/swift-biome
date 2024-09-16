protocol BranchAxis<Divergence>
{
    associatedtype Divergence:BranchDivergence

    subscript<Value>(field:FieldAccessor<Divergence, Value>) -> OriginalHead<Value>?
    {
        get
    }
    subscript<Value>(field:FieldAccessor<Divergence, Value>, 
        since revision:Version.Revision) -> OriginalHead<Value>?
    {
        get set
    }
}