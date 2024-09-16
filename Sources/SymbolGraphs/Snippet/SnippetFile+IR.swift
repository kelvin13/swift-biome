import JSON
import SymbolSource

extension SnippetFile
{
    private
    enum CodingKeys
    {
        static let name:String = "name"
        static let source:String = "source"
        static let dependencies:String = "dependencies"
    }

    var serialized:JSON
    {
        [
            CodingKeys.name: .string(self.name.string),
            CodingKeys.source: .string(self.source),
            CodingKeys.dependencies: .array(self.dependencies.map(\.serialized)),
        ]
    }

    init(from json:JSON) throws
    {
        self = try json.lint
        {
            .init(name: try $0.remove(CodingKeys.name,   as: String.self, 
                    ModuleIdentifier.init(_:)),
                dependencies: try $0.remove(CodingKeys.dependencies, as: [JSON].self)
                {
                    try $0.map(PackageDependency.init(from:))
                },
                source: try $0.remove(CodingKeys.source, as: String.self))
        }
    }
}