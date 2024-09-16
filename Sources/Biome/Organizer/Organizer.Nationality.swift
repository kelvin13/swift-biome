import HTML
import SymbolSource

extension Organizer 
{
    enum Nationality
    {
        case local 
        case foreign(PackageReference)
    }
}
extension Organizer.Nationality:Comparable 
{
    enum SortingKey:Comparable 
    {
        case local 
        case foreign(PackageIdentifier)
    }

    var sortingKey:SortingKey
    {
        switch self 
        {
        case .local: 
            return .local
        case .foreign(let nationality): 
            return .foreign(nationality.name)
        }
    }

    static 
    func == (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.sortingKey == rhs.sortingKey
    }
    static 
    func < (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.sortingKey < rhs.sortingKey
    }
}

extension Organizer.Nationality:HTMLOptionalConvertible
{
    var html:HTML.Element<Never>?
    {
        switch self 
        {
        case .local: 
            return nil
        case .foreign(let nationality):
            return nationality.html
        }
    }
}