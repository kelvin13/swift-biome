import JSON
import SymbolSource

extension SymbolGraph.CulturalPartition
{
    private
    enum CodingKeys
    {
        static let id:String = "id"
        static let dependencies:String = "dependencies"
        static let markdown:String = "markdown"
        static let sources:String = "sources"
        static let colonies:String = "colonies"
        static let vertices:String = "vertices"
        static let edges:String = "edges"
    }

    var serialized:JSON 
    {
        [
            CodingKeys.id: .string(self.id.string),
            CodingKeys.dependencies: .array(self.dependencies.map(\.serialized)),
            CodingKeys.markdown: .array(self.markdown.map(\.serialized)),
            CodingKeys.sources: .array(self.sources.map(\.serialized)),
            CodingKeys.colonies: .array(self.colonies.map(\.serialized)),
            CodingKeys.vertices: 
            [
                .number(self.vertices.lowerBound),
                .number(self.vertices.upperBound),
            ],
            CodingKeys.edges: .object(self.edges.serialized),
        ]
    }
    init(from json:JSON) throws 
    {
        self = try json.lint 
        {
            .init(
                id: try $0.remove(CodingKeys.id, as: String.self, ModuleIdentifier.init(_:)), 
                dependencies: try $0.remove(CodingKeys.dependencies, as: [JSON].self)
                {
                    try $0.map(PackageDependency.init(from:))
                }, 
                markdown: try $0.remove(CodingKeys.markdown, as: [JSON].self)
                {
                    try $0.map(MarkdownFile.init(from:)).sorted
                    {
                        $0.name < $1.name
                    }
                },
                sources: try $0.remove(CodingKeys.sources, as: [JSON].self)
                {
                    try $0.map(SwiftFile.init(from:)).sorted
                    {
                        $0.uri < $1.uri
                    }
                },
                colonies: try $0.remove(CodingKeys.colonies, as: [JSON].self)
                {
                    try $0.map(SymbolGraph.ColonialPartition.init(from:))
                },
                vertices: try $0.remove(CodingKeys.vertices)
                {
                    let tuple:[JSON] = try $0.as([JSON].self, count: 2)
                    return try tuple.load(0) ..< tuple.load(1)
                },
                edges: try $0.remove(CodingKeys.edges, [SymbolGraph.Edge<Int>].init(from:)))
        }
    }
}