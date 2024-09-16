struct IntrinsicSlice<Atom> where Atom:IntrinsicReference
{
    private 
    let base:IntrinsicBuffer<Atom>
    let endIndex:Atom.Offset

    init(_ base:IntrinsicBuffer<Atom>, upTo endIndex:Atom.Offset)
    {
        self.base = base 
        self.endIndex = endIndex
    }
}
extension IntrinsicSlice:PeriodAxis
{
    subscript<Value>(field:FieldAccessor<Atom.Divergence, Value>) -> PeriodHead<Value>
    {
        assert(field.key.offset < self.endIndex)

        return field.key.offset < self.startIndex ?
            .alternate(self.divergences[field.key]?[keyPath: field.alternate]) :
            .original(        self.base[field.key,    field: field.original])
    }
}
extension IntrinsicSlice:RandomAccessCollection
{
    typealias Index = Atom.Offset 
    typealias SubSequence = Self 
    
    var startIndex:Atom.Offset
    {
        self.base.startIndex
    }
    subscript(offset:Atom.Offset) -> Atom.Intrinsic
    {
        _read 
        {
            assert(self.indices ~= offset)
            yield  self.base[offset]
        }
    }
    subscript(range:Range<Atom.Offset>) -> Self
    {
        self.base[range]
    }
}
extension IntrinsicSlice
{
    struct Atoms
    {
        private 
        let base:IntrinsicBuffer<Atom>.Atoms
        private 
        let indices:Range<Index>

        fileprivate
        init(base:IntrinsicBuffer<Atom>.Atoms, indices:Range<Index>)
        {
            self.base = base
            self.indices = indices
        }

        subscript(id:Element.ID) -> Atom?
        {
            if  let atom:Atom = self.base[id], 
                self.indices ~= atom.offset
            {
                return atom
            }
            else 
            {
                return nil
            }
        }
    }

    subscript(contemporary atom:Atom) -> Atom.Intrinsic
    {
        _read
        {
            yield self.base[contemporary: atom]
        }
    }
    var divergences:[Atom: Atom.Divergence]
    {
        self.base.divergences
    }
    var atoms:Atoms
    {
        .init(base: self.base.atoms, indices: self.indices)
    }
}
