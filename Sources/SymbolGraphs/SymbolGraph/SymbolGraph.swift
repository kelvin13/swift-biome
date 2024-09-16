import SymbolSource 

public
enum SymbolGraphValidationError:Error
{
    case duplicateCulturalGraph(ModuleIdentifier)
    case missingLocalDependency(ModuleIdentifier)
    case cyclicLocalDependencies
    case cyclicDocumentationCommentDependency(SymbolIdentifier)
}

@frozen public
struct SymbolGraph:Equatable, Sendable
{
    public
    let id:PackageIdentifier

    public 
    let identifiers:Identifiers
    public private(set)
    var vertices:[Vertex<Int>]
    public
    let snippets:[SnippetFile]
    @usableFromInline private(set) 
    var partitions:[CulturalPartition]

    init(id:PackageIdentifier, identifiers:Identifiers,
        vertices:[Vertex<Int>],
        snippets:[SnippetFile],
        partitions:[CulturalPartition])
    {
        self.id = id
        self.identifiers = identifiers
        self.vertices = vertices
        self.snippets = snippets
        self.partitions = partitions
    }
}

private
struct SymbolIdentifierTable
{
    private(set)
    var identifiers:[SymbolIdentifier]
    private(set)
    var indices:[SymbolIdentifier: Int]

    init(capacity:Int)
    {
        self.identifiers = []
        self.identifiers.reserveCapacity(capacity)
        self.indices = .init(minimumCapacity: capacity)
    }

    func contains(_ identifier:SymbolIdentifier) -> Bool
    {
        self.indices.keys.contains(identifier)
    }

    mutating
    func append(contentsOf identifiers:some Sequence<SymbolIdentifier>) -> Range<Int>
    {
        let start:Int = self.identifiers.endIndex
        self.identifiers.append(contentsOf: identifiers)
        let end:Int = self.identifiers.endIndex
        self.indices.merge(zip(self.identifiers[start ..< end], start ..< end)) { $1 }
        return start ..< end
    }
}

struct SilentOutput:TextOutputStream
{
    func write(_:String)
    {
    }
}
struct VerboseOutput:TextOutputStream
{
    func write(_ string:String)
    {
        print(string)
    }
}

public
enum Diagnostic
{
    public
    enum Naturalization
    {
        case underscoredProtocol
        case underscoredProtocolMember
        case unavailableProtocolMember
    }

    case naturalized                (Naturalization, Path, culture:ModuleIdentifier)

    case prunedDuplicateComment     (from:Path, canonical:Path)
    case prunedEmptyInheritedComment(from:Path, canonical:Path)
    case optimizedInheritedComment  (from:Path, canonical:Path, skipped:Int)
}

extension SymbolGraph
{
    public
    init(compiling graph:RawSymbolGraph) throws
    {
        var none:[Diagnostic]? = nil
        try self.init(compiling: graph, diagnostics: &none)
    }
    public
    init(compiling graph:RawSymbolGraph, diagnostics:inout [Diagnostic]?) throws
    {
        let cultures:[RawCulturalGraph] = try graph.cultures.topologicallySorted(
            by: try graph.cultures.dependencies(localTo: graph.id))
        try self.init(id: graph.id, cultures: try cultures.map
            {
                try .init($0, diagnostics: &diagnostics)
            },
            snippets: graph.snippets,
            diagnostics: &diagnostics)
    }
    private
    init(id:PackageIdentifier, cultures:[CulturalGraph], snippets:[SnippetFile],
        diagnostics:inout [Diagnostic]?) throws
    {
        let capacity:Int = cultures.reduce(0)
        {
            $0 + $1.colonies.reduce(0) { $0 + $1.vertices.count }
        }

        // build the identifiers table. 
        var table:SymbolIdentifierTable = .init(capacity: capacity)

        var partitions:[[ColonialPartition]] = []
            partitions.reserveCapacity(cultures.count)
        for culture:CulturalGraph in cultures
        {
            var colonies:[ColonialPartition] = []
                colonies.reserveCapacity(culture.colonies.count)
            
            for colony:ColonialGraph in culture.colonies 
            {
                let sorted:[(shape:Shape, id:SymbolIdentifier)] = colony.vertices.compactMap
                {
                    table.contains($0.key) ? nil : (shape: $0.value.shape, id: $0.key)
                }
                .sorted
                {
                    $0 < $1
                }

                colonies.append(.init(namespace: colony.namespace, 
                    vertices: table.append(contentsOf: sorted.lazy.map(\.id))))
            }
            partitions.append(colonies)
        }

        var cohorts:[Range<Int>] = []
            cohorts.reserveCapacity(cultures.count)
        for culture:CulturalGraph in cultures
        {
            var external:Set<SymbolIdentifier> = []
            for colony:ColonialGraph in culture.colonies
            {
                colony.forEachIdentifier
                {
                    if !table.contains($0) { external.insert($0) }
                }
            }
            cohorts.append(table.append(contentsOf: external.sorted()))
        }
        try self.init(id: id, cultures: _move cultures, snippets: _move snippets,
            identifiers: _move table,
            colonies: _move partitions,
            cohorts: _move cohorts,
            vertices: capacity,
            diagnostics: &diagnostics)
    }
    private
    init(id:PackageIdentifier, cultures:[CulturalGraph], snippets:[SnippetFile],
        identifiers table:SymbolIdentifierTable,
        colonies:[[ColonialPartition]],
        cohorts:[Range<Int>],
        vertices:Int,
        diagnostics:inout [Diagnostic]?) throws
    {
        self.id = id
        self.snippets = snippets.sorted
        {
            $0.name < $1.name
        }
        self.vertices = []
        self.partitions = []
        self.vertices.reserveCapacity(vertices)
        self.partitions.reserveCapacity(cultures.count)
        for (culture, colonies):(CulturalGraph, [ColonialPartition]) in 
            zip(cultures, _move colonies)
        {
            let vertices:Range<Int> = 
                (colonies.first?.vertices.lowerBound ?? self.vertices.endIndex) ..<
                (colonies.last?.vertices.upperBound ?? self.vertices.endIndex)
            
            assert(self.vertices.endIndex == vertices.lowerBound)

            // all the same keys, just rearranged
            for (colony, partition):(ColonialGraph, ColonialPartition) in 
                zip(culture.colonies, colonies)
            {
                for id:SymbolIdentifier in table.identifiers[partition.vertices]
                {
                    self.vertices.append(colony.vertices[id]!.map { table.indices[$0]! })
                }
            }

            assert(self.vertices.endIndex == vertices.upperBound)


            var sourcemap:[String: [SwiftFile.Feature]] = [:]
            for colony:ColonialGraph in culture.colonies
            {
                for (uri, symbols):(String, [ColonialGraph.SourceFeature]) in 
                    colony.sourcemap 
                {
                    for symbol:ColonialGraph.SourceFeature in symbols 
                    {
                        sourcemap[uri, default: []].append(.init(line: symbol.line,
                            character: symbol.character,
                            vertex: table.indices[symbol.id]!))
                    }
                }
            }

            self.partitions.append(.init(id: culture.id, 
                dependencies: culture.dependencies, 
                markdown: culture.markdown,
                sources: sourcemap.map 
                {
                    .init(uri: $0.key, features: $0.value.sorted())
                }
                .sorted
                {
                    $0.uri < $1.uri
                },
                colonies: colonies,
                vertices: vertices,
                edges: culture.colonies.flatMap 
                {
                    $0.edges.map { $0.map { table.indices[$0]! } }
                }
                .sorted 
                {
                    // this is only a well-defined sort within the same module!
                    // this is not a well-defined sort if there are multiple edges of different types 
                    // between the same two vertices. this doesn’t affect the encoded output, since 
                    // we partition by relation type.
                    ($0.source, $0.target) < ($1.source, $1.target)
                }))
        }

        // uniquify hints
        var uptree:[Int: Int] = [:]
        for culture:CulturalGraph in _move cultures
        {
            for colony:ColonialGraph in culture.colonies
            {
                // synthetics generate hints that make sense to lib/SymbolGraphGen, 
                // but look like loopbacks to us. so we need to explicitly look for 
                // and ignore these self-hints.
                for hint:Hint<SymbolIdentifier> in colony.hints
                    where hint.source != hint.origin
                {
                    let hint:Hint<Int> = hint.map { table.indices[$0]! } 
                    if  hint.source < self.vertices.endIndex 
                    {
                        uptree[hint.source] = hint.origin
                    }
                }
            }
        }
        self.identifiers = .init(table: table.identifiers, cohorts: cohorts)
        try self.apply(hints: uptree, diagnostics: &diagnostics)
    }

    private mutating 
    func apply(hints:[Int: Int], diagnostics:inout [Diagnostic]?) throws
    {
        for (source, origin):(Int, Int) in hints 
        {
            if case nil = self.vertices[source].comment.extends 
            {
                self.vertices[source].comment.extends = origin
            }
        }
        // delete comments if a hint indicates it is duplicated. 
        // this does not preclude the need to prune again when documentation 
        // from multiple modules in the same package are combined (yet)
        // var pruned:Int = 0
        for index:Int in self.vertices.indices
        {
            let comment:Comment<Int> = self.vertices[index].comment 
            if  let string:String = comment.string, 
                let origin:Int = comment.extends, 
                    origin < self.vertices.endIndex, 
                case string? = self.vertices[origin].comment.string
            {
                self.vertices[index].comment.string = nil

                diagnostics?.append(.prunedDuplicateComment(
                    from: self.vertices[index].path, 
                    canonical: self.vertices[origin].path))
            }
        }
        // print("pruned \(pruned) duplicate comments")

        // fast-forward inheritance chains until we either reach a package 
        // boundary, or a local symbol that has documentation. 
        for index:Int in self.vertices.indices
        {
            let comment:Comment<Int> = self.vertices[index].comment 

            guard   case nil = comment.string,
                    var origin:Int = comment.extends, 
                        origin < self.vertices.endIndex
            else
            {
                continue 
            }

            var visited:Set<Int> = []
            fastforwarding:
            while true
            {
                guard case nil = visited.update(with: origin)
                else
                {
                    throw SymbolGraphValidationError
                        .cyclicDocumentationCommentDependency(self.identifiers.table[index])
                }

                let original:Comment<Int> = self.vertices[origin].comment
                switch (original.extends, original.string)
                {
                case (let next?, nil): 
                    if next < self.vertices.endIndex
                    {
                        origin = next 
                        // skipped += 1
                        continue fastforwarding
                    }
                    
                    self.vertices[index].comment.extends = origin
                
                case (_,          _?): 
                    self.vertices[index].comment.extends = origin
                
                case (nil,       nil): 
                    self.vertices[index].comment.extends = nil 
                    // dropped += 1
                }

                break fastforwarding
            }
        }
    }
}
// extension SymbolGraph:RandomAccessCollection
// {
//     @inlinable public
//     var startIndex:Int
//     {
//         self.vertices.startIndex
//     }
//     @inlinable public
//     var endIndex:Int
//     {
//         self.vertices.endIndex
//     }
//     @inlinable public
//     subscript(index:Int) -> (id:SymbolIdentifier, vertex:SymbolGraph.Vertex<Int>)
//     {
//         (self.identifiers.table[index], self.vertices[index])
//     }
// }

extension SymbolGraph
{
    @inlinable public
    var cultures:Cultures
    {
        .init(self)
    }

    @frozen public
    struct Cultures
    {
        @usableFromInline
        let graph:SymbolGraph

        @inlinable public
        init(_ graph:SymbolGraph)
        {
            self.graph = graph
        }
    }
}
extension SymbolGraph.Cultures:RandomAccessCollection
{
    @inlinable public
    var startIndex:Int
    {
        self.graph.partitions.startIndex
    }
    @inlinable public
    var endIndex:Int
    {
        self.graph.partitions.endIndex
    }
    @inlinable public
    subscript(index:Int) -> SymbolGraph.Culture
    {
        return .init(partition: self.graph.partitions[index], 
            identifiers: self.graph.identifiers.table, 
            vertices: self.graph.vertices)
    }
}
