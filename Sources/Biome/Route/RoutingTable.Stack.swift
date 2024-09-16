extension RoutingTable 
{
    // 24B stride. the ``many`` case should be quite rare, since we are now 
    // encoding path orientation in the leaf key.
    enum Stack:Sendable 
    {
        // if there is no feature index, the natural index is duplicated. 
        case one ((Composite, Version.Revision))
        case many([Symbol: Substack])
        
        func forEach(_ body:(Composite, Version.Revision) throws -> ()) rethrows 
        {
            switch self
            {
            case .one((let composite, let revision)):
                try body(composite, revision)
            
            case .many(let composites):
                for (base, diacritics):(Symbol, Substack) in composites 
                {
                    switch diacritics
                    {
                    case .one((let diacritic, let revision)):
                        try body(.init(base, diacritic), revision)
                    
                    case .many(let diacritics):
                        for (diacritic, revision):(Diacritic, Version.Revision) in diacritics
                        {
                            try body(.init(base, diacritic), revision)
                        }
                    }
                }
            }
        }
    }
}
extension RoutingTable.Stack
{
    func reverted(to revision:Version.Revision) -> Self?
    {
        var reverted:Self? = nil
        self.forEach
        {
            if $1 <= revision
            {
                reverted.insert($0, revision: $1)
            }
        }
        return reverted
    }
}
extension RoutingTable.Stack?
{
    mutating 
    func insert(_ element:Composite, revision:Version.Revision)
    {
        switch _move self
        {
        case nil: 
            self = .one((element, revision))
        case .one((element, let revision))?: 
            self = .one((element, revision)) 
        case .one(let other)?: 
            let two:[Symbol: RoutingTable.Substack]
            // overloading on host id is extremely rare; the column 
            // array layout is inefficient, but allows us to represent the 
            // more-common row layout efficiently
            if other.0.base == element.base 
            {
                two = 
                [
                    other.0.base: .many([other.0.diacritic: other.1, element.diacritic: revision])
                ]
            }
            else 
            {
                two = 
                [
                    other.0.base: .one((other.0.diacritic, other.1)), 
                    element.base: .one((element.diacritic, revision))
                ]
            }
            self = .many(two)
        
        case .many(var subgroups)?:
            subgroups[element.base].insert(element.diacritic, revision: revision)
            self = .many(subgroups)
        }
    }
}
