import JSON
import SymbolSource

extension SymbolGraph.Identifiers
{
    private
    enum CodingKeys
    {
        static let table:String = "table"
        static let cohorts:String = "cohorts"
    }

    var serialized:JSON
    {
        [
            CodingKeys.table: .array(self.table.map { .string($0.string) }),
            CodingKeys.cohorts: .array(self.cohorts.map 
            { 
                [
                    .number($0.lowerBound),
                    .number($0.upperBound),
                ]
            }),
        ]
    }

    init(from json:JSON) throws
    {
        self = try json.lint
        {
            .init(table: try $0.remove(CodingKeys.table, as: [JSON].self)
                {
                    try $0.map(SymbolIdentifier.init(from:))
                },
                cohorts: try $0.remove(CodingKeys.cohorts, as: [JSON].self)
                {
                    try $0.map
                    {
                        let tuple:[JSON] = try $0.as([JSON].self, count: 2)
                        return try tuple.load(0) ..< tuple.load(1)
                    }
                })
        }
    }
}