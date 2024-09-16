import PackagePlugin

extension Build
{
    struct Dependency
    {
        let nationality:Package.ID
        let cultures:[String]

        init(nationality:Package.ID, cultures:[String])
        {
            self.nationality = nationality
            self.cultures = cultures
        }
    }
}
extension Build.Dependency
{
    init(_ item:(Package.ID, [SwiftSourceModuleTarget]))
    {
        self.init(nationality: item.0, cultures: item.1.map(\.name))
    }
}
extension Build.Dependency:CustomStringConvertible
{
    var description:String
    {
        """
        {\
        "nationality": "\(self.nationality)", \
        "cultures": [\(self.cultures.lazy.map { "\"\($0)\"" }.joined(separator: ", "))]\
        }
        """
    }
}

extension Build
{
    struct Culture
    {
        let id:String
        let dependencies:[Dependency]
        let include:[Path]
    }
    struct Snippet
    {
        let id:String
        let dependencies:[Dependency]
        let sources:[Path]
    }
}
extension Build.Culture:CustomStringConvertible
{
    var description:String
    {
        """
        {\
        "id": "\(self.id)", \
        "dependencies": [\(self.dependencies.lazy.map(\.description).joined(separator: ", "))], \
        "include": [\(self.include.lazy.map { "\"\($0)\"" }.joined(separator: ", "))]\
        }
        """
    }
}
extension Build.Snippet:CustomStringConvertible
{
    var description:String
    {
        """
        {\
        "id": "\(self.id)", \
        "dependencies": [\(self.dependencies.lazy.map(\.description).joined(separator: ", "))], \
        "sources": [\(self.sources.lazy.map { "\"\($0)\"" }.joined(separator: ", "))]\
        }
        """
    }
}

struct Build
{
    let id:Package.ID
    var cultures:[Culture]
    var snippets:[Snippet]

    init(id:Package.ID, cultures:[Culture] = [], snippets:[Snippet] = [])
    {
        self.id = id
        self.cultures = cultures
        self.snippets = snippets
    }
}
extension Build:CustomStringConvertible
{
    var description:String
    {
        """
        {\
        "symbolgraph_tools_version": 4, \
        "id": "\(self.id)", \
        "cultures": [\(self.cultures.lazy.map(\.description).joined(separator: ", "))], \
        "snippets": [\(self.snippets.lazy.map(\.description).joined(separator: ", "))]\
        }
        """
    }
}