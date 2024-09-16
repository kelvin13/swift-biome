extension RoutingTable 
{
    enum Substack:Sendable 
    {
        case one ((Diacritic, Version.Revision))
        case many([Diacritic: Version.Revision])
    }
}

extension RoutingTable.Substack? 
{
    mutating 
    func insert(_ element:Diacritic, revision:Version.Revision)
    {
        switch _move self
        {
        case nil: 
            self = .one((element, revision))
        case .one((element, let revision))?: 
            self = .one((element, revision))
        case .one(let other)?: 
            self = .many([other.0: other.1, element: revision])
        case .many(var diacritics)?:
            { _ in }(&diacritics[element, default: revision])
            self = .many(diacritics)
        }
    }
}