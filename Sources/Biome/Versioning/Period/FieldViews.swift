protocol FieldViews<Axis, Value>:Collection where Element == Period<Axis>.FieldView<Value>
{
    associatedtype Axis:PeriodAxis
    associatedtype Value:Equatable

    subscript(index:Int) -> Period<Axis>.FieldView<Value>
    {
        get
    }
}
extension FieldViews
{
    private 
    func values(of field:FieldAccessor<Axis.Divergence, Value>) -> Timeline<Self>
    {
        .init(self, field: field)
    }
    func value(of field:FieldAccessor<Axis.Divergence, Value>) -> Value?
    {
        for (value, _):(Value, Version.Revision) in self.values(of: field).joined()
        {
            return value
        }
        return nil
    }

    func latestVersion(of field:FieldAccessor<Axis.Divergence, Value>, 
        where predicate:(Value) throws -> Bool) rethrows -> Version?
    {
        var candidate:Version? = nil
        for values:Timeline<Self>.FieldValues in self.values(of: field)
        {
            if case nil = candidate 
            {
                candidate = values.latest
            }
            for keyframe:(value:Value, since:Version.Revision) in values
            {
                if try predicate(keyframe.value) 
                {
                    return candidate 
                }
                else if let version:Version = values.version(before: keyframe.since)
                {
                    candidate = version
                }
            }
        }
        return nil 
    }
}
