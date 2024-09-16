import JSON
import SymbolSource

extension SymbolGraph.ColonialPartition
{
    var serialized:JSON
    {
        [
            .string(self.namespace.string),
            .number(self.vertices.lowerBound),
            .number(self.vertices.upperBound),
        ]
    }

    init(from json:JSON) throws
    {
        let tuple:[JSON] = try json.as([JSON].self, count: 3)
        self.init(
            namespace: try tuple.load(0, as: String.self, ModuleIdentifier.init(_:)), 
            vertices: try tuple.load(1) ..< tuple.load(2))
    }
}