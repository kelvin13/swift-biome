import JSON
import SymbolSource

extension SymbolGraph 
{
    private
    enum CodingKeys
    {
        static let id:String = "id"
        static let identifiers:String = "identifiers"
        static let vertices:String = "vertices"
        static let snippets:String = "snippets"
        static let cultures:String = "cultures"
        static let shapes:String = "shapes"
    }
    @inlinable public 
    init<UTF8>(utf8:UTF8) throws where UTF8:Collection<UInt8> 
    {
        try self.init(from: try JSON.init(parsing: utf8))
    }
    public 
    init(from json:JSON) throws 
    {
        self = try json.lint 
        {
            let shapes:[(Shape, Range<Int>)] = try $0.remove(CodingKeys.shapes)
            {
                let flattened:[JSON] = try $0.as([JSON].self) { $0 % 3 == 0 }
                var shapes:[(Shape, Range<Int>)] = []
                    shapes.reserveCapacity(flattened.count / 3)
                for start:Int in stride(
                    from: flattened.startIndex, 
                    to: flattened.endIndex, 
                    by: 3)
                {
                    let shape:Shape = try flattened.load(start, as: String.self)
                    {
                        if let shape:Shape = .init($0)
                        {
                            return shape
                        }
                        else 
                        {
                            throw JSON.PrimitiveError.matching(
                                variant: .string($0), 
                                as: Shape.self)
                        }
                    }
                    let range:Range<Int> = 
                        try flattened.load(start + 1) ..< flattened.load(start + 2)
                    
                    shapes.append((shape, range))
                }
                return shapes
            }
            return .init(id: try $0.remove(CodingKeys.id, as: String.self, 
                    PackageIdentifier.init(_:)), 
                identifiers: try $0.remove(CodingKeys.identifiers, Identifiers.init(from:)),
                vertices: try $0.remove(CodingKeys.vertices) 
                {
                    try .init(from: $0, shapes: shapes)
                },
                snippets: try $0.remove(CodingKeys.snippets, as: [JSON].self)
                {
                    try $0.map(SnippetFile.init(from:)).sorted
                    {
                        $0.name < $1.name
                    }
                }, 
                partitions: try $0.remove(CodingKeys.cultures, as: [JSON].self)
                {
                    try $0.map(CulturalPartition.init(from:))
                })
        }
    }
    public 
    var serialized:JSON 
    {
        [
            CodingKeys.id: .string(self.id.string),
            CodingKeys.identifiers: self.identifiers.serialized,
            CodingKeys.snippets: .array(self.snippets.map(\.serialized)),
            CodingKeys.cultures: .array(self.partitions.map(\.serialized)),
            CodingKeys.vertices: .array(self.vertices.map(\.serialized)),
            CodingKeys.shapes: .array(self.vertices.shapes),
        ]
    }
}


extension RangeReplaceableCollection<SymbolGraph.Vertex<Int>> 
{
    init(from json:JSON, shapes:some Sequence<(Shape, Range<Int>)>) throws 
    {
        let vertices:[JSON] = try json.as([JSON].self)
        self.init()
        self.reserveCapacity(vertices.count)
        for (shape, range):(Shape, Range<Int>) in shapes 
        {
            for index:Int in range 
            {
                self.append(try vertices.load(index) 
                { 
                    try SymbolGraph.Vertex<Int>.init(from: $0, shape: shape) 
                })
            }
        }
    }
}
extension Collection<SymbolGraph.Vertex<Int>> where Index == Int 
{
    var shapes:[JSON]
    {
        guard var shape:Shape = self.first?.shape 
        else 
        {
            return []
        }
        var shapes:[(shape:Shape, range:Range<Int>)] = []
        var start:Int = self.startIndex
        for (end, vertex):(Int, SymbolGraph.Vertex<Int>) in zip(self.indices, self).dropFirst()
        {
            if vertex.shape != shape 
            {
                shapes.append((shape, start ..< end))
                shape = vertex.shape
                start = end 
            }
        }
        if start < self.endIndex
        {
            shapes.append((shape, start ..< self.endIndex))
        }
        return shapes.flatMap 
        { 
            [
                .string($0.shape.description), 
                .number($0.range.lowerBound),
                .number($0.range.upperBound),
            ] 
        }
    }
}

extension RangeReplaceableCollection<SymbolGraph.Edge<Int>> 
{
    init(from json:JSON) throws 
    {
        self.init()
        try json.lint 
        {
            try $0.pop("conformer") 
            {
                let points:[JSON] = try $0.as([JSON].self) { $0 % 3 == 0 }
                for start:Int in stride(from: points.startIndex, to: points.endIndex, by: 3)
                {
                    self.append(.init(try points.load(start), 
                        is: .conformer(try points.load(start + 2, as: [JSON].self) 
                        {
                            try $0.map(Generic.Constraint<Int>.init(from:))
                        }), 
                        of: try points.load(start + 1)))
                }
            }
            for (key, relation):(String, SymbolGraph.Edge<Int>.Relation) in 
            [
                ("feature", .feature), 
                ("member", .member), 
                ("subclass", .subclass), 
                ("override", .override), 
                ("requirement", .requirement), 
                ("optionalRequirement", .optionalRequirement), 
                ("defaultImplementation", .defaultImplementation), 
            ] 
            {
                try $0.pop(key) 
                {
                    let points:[JSON] = try $0.as([JSON].self) { $0 % 2 == 0 }
                    for start:Int in stride(from: points.startIndex, to: points.endIndex, by: 2)
                    {
                        self.append(.init(try points.load(start), is: relation, 
                            of: try points.load(start + 1)))
                    }
                }
            }
        }
    }
}
extension Sequence<SymbolGraph.Edge<Int>> 
{
    var serialized:[(key:String, value:JSON)]
    {
        var feature:[(Int, Int)] = []
        var member:[(Int, Int)] = []
        var subclass:[(Int, Int)] = []
        var override:[(Int, Int)] = []
        var requirement:[(Int, Int)] = []
        var optionalRequirement:[(Int, Int)] = []
        var defaultImplementation:[(Int, Int)] = []
        var conformer:[(Int, Int, [Generic.Constraint<Int>])] = []
        for edge:SymbolGraph.Edge<Int> in self 
        {
            switch edge.relation 
            {
            case .feature:                             feature.append((edge.source, edge.target))
            case .member:                               member.append((edge.source, edge.target))
            case .subclass:                           subclass.append((edge.source, edge.target))
            case .override:                           override.append((edge.source, edge.target))
            case .requirement:                     requirement.append((edge.source, edge.target))
            case .optionalRequirement:     optionalRequirement.append((edge.source, edge.target))
            case .defaultImplementation: defaultImplementation.append((edge.source, edge.target))

            case .conformer(let conditions): conformer.append((edge.source, edge.target, conditions))
            }
        }
        var items:[(key:String, value:JSON)] = conformer.isEmpty ? [] :
        [
            ("conformer", .array(conformer.flatMap 
            {
                [.number($0.0), .number($0.1), .array($0.2.map(\.serialized))]
            }))
        ]
        for (key, edges):(String, [(Int, Int)]) in 
        [
            ("feature", feature),
            ("member", member),
            ("subclass", subclass),
            ("override", override),
            ("requirement", requirement),
            ("optionalRequirement", optionalRequirement),
            ("defaultImplementation", defaultImplementation),
        ] 
            where !edges.isEmpty
        {
            items.append((key, .array(edges.flatMap { [.number($0.0), .number($0.1)] })))
        }
        return items
    }
}
