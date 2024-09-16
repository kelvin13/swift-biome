import HTML 
import SymbolSource

extension Organizer 
{
    enum Culture
    {
        case primary 
        case accepted(ModuleReference)
        case nonaccepted(ModuleReference, PackageReference)
    }
}
extension Organizer.Culture:Comparable 
{
    enum SortingKey:Comparable 
    {
        case primary 
        case accepted(ModuleIdentifier)
        case nonaccepted(PackageIdentifier, ModuleIdentifier)
    }

    var sortingKey:SortingKey
    {
        switch self 
        {
        case .primary: 
            return .primary
        case .accepted(let culture): 
            return .accepted(culture.name)
        case .nonaccepted(let culture, let nationality): 
            return .nonaccepted(nationality.name, culture.name)
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

extension Organizer.Culture:HTMLConvertible
{
    var htmls:[HTML.Element<Never>]
    {
        switch self 
        {
        case .primary: 
            return [] 
        case .accepted(let culture):
            return [culture.html]
        case .nonaccepted(let culture, let nationality):
            return [culture.html, nationality.html]
        }
    }
}