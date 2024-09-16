@testable import Biome

extension SymbolGraph 
{
    static 
    func mock(module:ModuleIdentifier, 
        symbols:(kind:String, id:String, path:[String])...,
        relationships:(kind:String, source:String, target:String)...) 
        throws -> Self
    {
        let json:String = 
        """
        {
            "module": 
            {
                "name": "\(module)"
            },
            "symbols":
            [
            \(symbols.map 
            {
                """
                {
                    "kind": 
                    {
                        "identifier": "\($0.kind)"
                    },
                    "identifier":
                    {
                        "precise": "s:\($0.id)"
                    },
                    "pathComponents": [\($0.path.map { "\"\($0)\"" }.joined(separator: ", "))],
                    "names":
                    {
                        "subHeading": []
                    },
                    "declarationFragments": [],
                    "accessLevel": "public"
                }
                """
            }.joined(separator: ", "))
            ],
            "relationships": 
            [
            \(relationships.map 
            {
                """
                {
                    "kind": "\($0.kind)",
                    "source": "s:\($0.source)",
                    "target": "s:\($0.target)"
                }
                """
            }.joined(separator: ", "))
            ]
        }
        """
        return .init(id: module, subgraphs: 
        [
            try .init(utf8: json.utf8, culture: module),
        ])
    }
}

@main 
enum Main 
{
    static 
    func main() throws 
    {
        let extant:SymbolGraph = try .mock(module: "Swift", 
            symbols:
                ("swift.enum",          "Foo",      ["Foo"]),
                ("swift.type.property", "Foobar",   ["Foo", "bar"]),
                ("swift.method",        "Foobaz",   ["Foo", "baz(_:)"]), 
            relationships: 
                ("memberOf",    "Foobaz",   "Foo"))
        
        let extinct:SymbolGraph = try .mock(module: "Swift", 
            symbols:
                ("swift.enum",          "Foo",      ["Foo"]),
                ("swift.type.property", "Foobar",   ["Foo", "bar"]))
        
        var service:Service = .init()
        for (i, branch, fork, graph):(Int, String, String?, SymbolGraph) in 
        [
            ( 1, "master",                                          nil, extinct),
            ( 2, "master",                                          nil, extinct),
            ( 3, "master",                                          nil, extinct),
            ( 4,            "test1", "master:2024-01-03-a",              extinct),
            ( 5,            "test1",                                nil, extant),
            ( 6,            "test1",                                nil, extant),
            ( 7, "master",                                          nil, extinct),
            ( 8,            "test1",                                nil, extant),
            ( 9, "master",                                          nil, extant),
            (10,                        "test2", "test1:2024-01-08-a",   extinct),
            (11,            "test1",                                nil, extinct),
            (12,            "test1",                                nil, extinct),
            (13,            "test1",                                nil, extant),
            (14,                        "test2",                    nil, extant),
            (15,                        "test2",                    nil, extant),
        ]
        {
            try service.updatePackage("swift-standard-library", 
                resolved: .init(pins: [.init(id: "swift-standard-library", 
                    revision: "\(i)", 
                    requirement: .branch(branch))]),
                branch: branch,
                fork: fork,
                date: .init(year: .init(gregorian: 2024), month: 1, day: i, hour: 0x61),
                graphs: [graph])
        }
        
        let selector:Version.Selector = .init(parsing: "test2:2024-01-15-a")!
        let version:Version = service.packages.swift.tree.find(selector)!

        let fasces:Fasces = service.packages.swift.tree.fasces(through: version)
        let symbol:PluralPosition<Symbol> = 
            fasces.symbols.find(Symbol.ID.init(.swift, "Foobaz".utf8))!
        let evolution:Evolution = .init(for: symbol, in: service.packages.swift.tree, 
            history: service.packages.swift.metadata.symbols)
        for row:Evolution.Row in evolution.rows 
        {
            print(row)
        }
    }
}