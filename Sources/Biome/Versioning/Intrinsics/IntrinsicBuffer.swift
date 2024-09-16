extension IntrinsicBuffer:Sendable 
    where   Atom:Sendable, 
            Atom.Intrinsic:Sendable, 
            Atom.Intrinsic.ID:Sendable, 
            Atom.Divergence:Sendable, 
            Atom.Divergence.Base:Sendable
{
}

extension IntrinsicBuffer
{
    struct Intrinsics
    {
        private 
        var storage:[(element:Atom.Intrinsic, base:Divergence.Base)] 
        let startIndex:Atom.Offset

        private
        init(startIndex:Atom.Offset, storage:[(element:Atom.Intrinsic, base:Divergence.Base)])
        {
            self.storage = storage
            self.startIndex = startIndex
        }
        init(startIndex:Atom.Offset)
        {
            self.init(startIndex: startIndex, storage: [])
        }
    }
}
extension IntrinsicBuffer.Intrinsics
{
    mutating 
    func append(id:Atom.Intrinsic.ID, group:Atom.Group,
        creator create:(Atom.Intrinsic.ID, Atom) throws -> Atom.Intrinsic) rethrows -> Atom
    {
        let atom:Atom = .init(group, offset: self.endIndex)
        self.storage.append((try create(id, atom), .init()))
        return atom 
    }
    mutating 
    func remove(from index:Atom.Offset)
    {
        self.storage.removeSubrange(Int.init(index - self.startIndex)...)
    }
    mutating 
    func removeAll()
    {
        self.storage = []
    }
}
extension IntrinsicBuffer.Intrinsics
{
    func suffix(from index:Atom.Offset) -> Self
    {
        .init(startIndex: indices.lowerBound, storage: self.storage)
    }
}
extension IntrinsicBuffer.Intrinsics:RandomAccessCollection
{
    var endIndex:Atom.Offset
    {
        self.startIndex + Atom.Offset.init(self.storage.count)
    }
    subscript(index:Atom.Offset) -> (element:Atom.Intrinsic, base:Atom.Divergence.Base)
    {
        _read 
        {
            yield  self.storage[.init(index - self.startIndex)]
        }
        _modify
        {
            yield &self.storage[.init(index - self.startIndex)]
        }
    }
}

struct IntrinsicBuffer<Atom> where Atom:IntrinsicReference
{
    private(set)
    var atoms:Atoms
    private(set)
    var divergences:[Atom: Atom.Divergence]
    private 
    var intrinsics:Intrinsics
    
    private 
    init(divergences:[Atom: Atom.Divergence],
        intrinsics:Intrinsics,
        atoms:Atoms) 
    {
        self.divergences = divergences
        self.intrinsics = intrinsics
        self.atoms = atoms
    }
    init(startIndex:Atom.Offset) 
    {
        self.divergences = [:]
        self.intrinsics = .init(startIndex: startIndex)
        self.atoms = .init()
    }
}
extension IntrinsicBuffer
{
    mutating 
    func insert(_ id:Atom.Intrinsic.ID, group:Atom.Group, 
        creator create:(Atom.Intrinsic.ID, Atom) throws -> Atom.Intrinsic) rethrows -> Atom
    {
        if let atom:Atom = self.atoms[id]
        {
            return atom 
        }
        else 
        {
            // create records for elements if they do not yet exist 
            let atom:Atom = try self.intrinsics.append(id: id, group: group,
                creator: create)
            self.atoms[id] = atom
            return atom 
        }
    }
    mutating 
    func revert(to rollbacks:History.Rollbacks, through end:Atom.Offset)
    {
        self.intrinsics.remove(from: end)
        for index:Atom.Offset in self.intrinsics.indices
        {
            self.intrinsics[index].base.revert(to: rollbacks)
        }
        self.divergences.revert(to: rollbacks)
        self.atoms = self.atoms.filter { $0.offset < end }
    }
    mutating 
    func revert()
    {
        self.intrinsics.removeAll()
        self.divergences = [:]
        self.atoms = .init()
    }
}
extension IntrinsicBuffer:BranchAxis
{
    private(set)
    subscript<Value>(key:Atom, 
        field field:WritableKeyPath<Divergence.Base, Value>) -> Value
    {
        _read
        {
            yield  self.intrinsics[key.offset].base[keyPath: field]
        }
        _modify
        {
            yield &self.intrinsics[key.offset].base[keyPath: field]
        }
    }

    subscript<Value>(field:FieldAccessor<Atom.Divergence, Value>) -> OriginalHead<Value>?
    {
        _read
        {
            if field.key.offset < self.startIndex 
            {
                yield  self.divergences[field.key]?[keyPath: field.alternate]?.head
            }
            else
            {
                yield  self[field.key, field: field.original]
            }
        }
    }
    subscript<Value>(field:FieldAccessor<Atom.Divergence, Value>,
        since revision:Version.Revision) -> OriginalHead<Value>?
    {
        _read
        {
            yield self[field]
        }
        _modify
        {
            if field.key.offset < self.startIndex
            {
                yield &self.divergences[field.key, default: .init()][keyPath: field.alternate][since: revision]
            }
            else 
            {
                yield &self[field.key, field: field.original]
            }
        }
    }
}
extension IntrinsicBuffer:RandomAccessCollection 
{
    var startIndex:Atom.Offset
    {
        self.intrinsics.startIndex
    }
    var endIndex:Atom.Offset
    {
        self.intrinsics.endIndex
    }

    subscript(index:Atom.Offset) -> Atom.Intrinsic
    {
        _read
        {
            yield  self.intrinsics[index].element
        }
        _modify
        {
            yield &self.intrinsics[index].element
        }
    }
    
    subscript(indices:Range<Atom.Offset>) -> IntrinsicSlice<Atom> 
    {
        .init(.init(divergences: self.divergences,
                intrinsics: self.intrinsics.suffix(from: indices.lowerBound),
                atoms: self.atoms),
            upTo: indices.upperBound)
    }
    subscript(prefix:PartialRangeUpTo<Atom.Offset>) -> IntrinsicSlice<Atom> 
    {
        .init(self, upTo: prefix.upperBound)
    }
    subscript(_:UnboundedRange) -> IntrinsicSlice<Atom> 
    {
        .init(self, upTo: self.endIndex)
    }
}
extension IntrinsicBuffer
{
    struct Atoms
    {
        private 
        var table:[Element.ID: Atom]

        private 
        init(_ table:[Element.ID: Atom])
        {
            self.table = table
        }
        init()
        {
            self.init([:])
        }

        subscript(id:Element.ID) -> Atom?
        {
            _read
            {
                yield  self.table[id]
            }
            _modify
            {
                yield &self.table[id]
            }
        }

        func filter(where predicate:(Atom) throws -> Bool) rethrows -> Self
        {
            .init(try self.table.filter { try predicate($0.value) })
        }
    }

    // needed to workaround a compiler crash: https://github.com/apple/swift/issues/60841
    subscript(_contemporary atom:Atom) -> Element
    {
        self[atom.offset]
    }
    subscript(contemporary atom:Atom) -> Element
    {
        _read
        {
            yield  self[atom.offset]
        }
        _modify
        {
            yield &self[atom.offset]
        }
    }
}
