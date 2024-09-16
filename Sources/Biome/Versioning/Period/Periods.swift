protocol Periods<Axis>:Collection where Element == Period<Axis>
{
    associatedtype Axis:PeriodAxis

    subscript(index:Int) -> Period<Axis>
    {
        get
    }
}
extension Periods
{
    func find<Atom>(_ id:Atom.Intrinsic.ID) -> AtomicPosition<Atom>? 
        where Axis == IntrinsicSlice<Atom>
    {
        for period:Period<Axis> in self 
        {
            if let atom:Atom = period.axis.atoms[id]
            {
                return atom.positioned(period.branch)
            }
        }
        return nil
    }
}
