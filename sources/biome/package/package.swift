import Resource

public 
struct Package:Identifiable, Sendable
{
    /// A globally-unique index referencing a package. 
    struct Index:Hashable, Sendable 
    {
        let bits:UInt16
        
        var offset:Int 
        {
            .init(self.bits)
        }
        init(offset:Int)
        {
            self.bits = .init(offset)
        }
    }
    
    typealias Opinion = (symbol:Symbol.Index, has:Symbol.Trait)

    /* struct Dependency
    {
        let package:Int 
        let imports:[Int]
    }  */
    
    public 
    let id:ID
    private 
    let index:Index 
    private 
    var tag:Resource.Tag?
    private(set)
    var module:(buffer:[Module], indices:[Module.ID: Module.Index]),
        symbol:(buffer:[Symbol], indices:[Symbol.ID: Symbol.Index])
    private 
    var groups:[Symbol.Key: Symbol.Group]
    
    var name:String 
    {
        self.id.string
    }
    
    init(id:ID, index:Index)
    {
        self.id = id 
        self.index = index
        
        self.tag = "2.0.0"
        self.module.buffer = []
        self.symbol.buffer = []
        self.module.indices = [:]
        self.symbol.indices = [:]
        self.groups = [:]
    }
    
    mutating 
    func update(with opinions:[Opinion], from package:Index)
    {
        var traits:[Int: [Symbol.Trait]] = [:]
        for (symbol, trait):(Symbol.Index, Symbol.Trait) in opinions 
        {
            traits[symbol.offset, default: []].append(trait)
        }
        for (offset, traits):(Int, [Symbol.Trait]) in traits 
        {
            self.symbol.buffer[offset].update(traits: traits, from: package)
        }
    }
    
    mutating 
    func update(with graphs:[Module.Graph], given ecosystem:Ecosystem, paths:inout PathTable) 
        throws -> [Index: [Opinion]]
    {
        var opinions:[Index: [Opinion]] = [:]
        var buffer:NodeBuffer = try self.register(graphs, given: ecosystem)
        let scopes:[Scope] = self.module.buffer.map 
        {
            self.scope(from: $0, given: ecosystem)
        }
        for (scope, graph):(Scope, Module.Graph) in zip(scopes, graphs)
        {
            for edge:Edge in graph.edges.joined()
            {
                let (statement, secondary, sponsorship):Edge.Statements = try edge.statements(given: scope)
                {
                    buffer[$0]?.vertex.color ?? ecosystem[$0].color
                }
                if  case let (foreign, has: trait)? = 
                    try buffer.link(statement.subject, statement.predicate, accordingTo: scope.vantage)
                {
                    opinions[foreign.module.package, default: []].append((foreign, has: trait))
                }
                if  let statement:Symbol.Statement = secondary, 
                    case let (foreign, has: trait)? = 
                    try buffer.link(statement.subject, statement.predicate, accordingTo: scope.vantage)
                {
                    opinions[foreign.module.package, default: []].append((foreign, has: trait))
                }
                if  case let (sponsored, by: sponsor)? = sponsorship,
                    case .documented(let comment)? = buffer[sponsor]?.legality ?? ecosystem[sponsor].legality
                {
                    try buffer.deduplicate(sponsored, against: comment, from: sponsor)
                }
            }
        }
        try self.register(buffer, given: scopes, paths: &paths)
        return opinions
    }
}
extension Package 
{
    private 
    func scope(from module:Module, given ecosystem:Ecosystem) -> Scope 
    {
        // compute scope 
        let filter:Set<Module.Index> = ([module.index] as Set).union(module.dependencies.joined())
        let lenses:Set<Index> = .init(filter.map(\.package))
        return .init(vantage: module.index, filter: filter, lenses: lenses.map 
        {
            $0 == self.index ? self.symbol.indices : ecosystem[$0].symbol.indices
        })
    }
    private 
    func index(of module:Module.ID) throws -> Module.Index 
    {
        if let index:Module.Index = self.module.indices[module] 
        {
            return index 
        }
        else 
        {
            throw Module.ResolutionError.target(module, in: self.id)
        }
    }
    // this method leaves `self` in a temporarily-invalid state, as it creates
    // modules that reference symbols in the symbol buffer that do not yet exist.
    private mutating 
    func register(_ graphs:[Module.Graph], given ecosystem:Ecosystem) throws -> NodeBuffer
    {
        assert(self.module.buffer.isEmpty)
        // assign module indices
        // TODO: handle version dimension
        for (offset, graph):(Int, Module.Graph) in graphs.enumerated() 
        {
            self.tag *= graph.tag
            self.module.indices[graph.core.namespace] = .init(self.index, offset: offset)
        }
        
        var buffer:NodeBuffer = .init(package: self.index)
        for (offset, graph):(Int, Module.Graph) in graphs.enumerated() 
        {
            let dependencies:[[(Module.ID, Module.Index)]] = try graph.dependencies.map 
            {
                if let package:Self = self.id == $0.package ? self : ecosystem[$0.package]
                {
                    return try $0.modules.map { ($0, try package.index(of: $0)) }
                }
                else 
                {
                    throw Package.ResolutionError.dependency($0.package, of: self.id)
                }
            }
            //  all of a module’s dependencies have unique names, so build a lookup 
            //  table for them. this lookup table enables this function to 
            //  run in quadratic time; otherwise it would be cubic!
            let bystanders:[Module.ID: Module.Index] = 
                .init(uniqueKeysWithValues: dependencies.joined())
            
            let culture:(id:Module.ID, index:Module.Index) =
                (graph.core.namespace, .init(self.index, offset: offset))
            
            let core:Symbol.IndexRange = .init(culture.index, 
                offsets: try buffer.extend(with: graph.core.vertices)
            {
                try self.register($1, at: $0, culture: culture)
            })
            // let core:Symbol.IndexRange = .init(culture.index, offsets: 
            //     try self.register(graph.core, culture: culture, buffer: &buffer))
            let colonies:[Symbol.ColonialRange] = try graph.colonies.map
            {
                guard let bystander:Module.Index = bystanders[$0.namespace]
                else 
                {
                    throw Module.ResolutionError.dependency($0.namespace, of: culture.id)
                }
                return .init(namespace: bystander, 
                    offsets: try buffer.extend(with: $0.vertices)
                {
                    try self.register($1, at: $0, culture: culture)
                })
            }
            // a vertex is top-level if it has exactly one path component. 
            let toplevel:[Symbol.Index] = core.filter 
            {
                buffer.nodes[$0.offset].vertex.path.count == 1
            }
            let module:Module = .init(id: culture.id, 
                core: core, colonies: colonies, toplevel: toplevel, 
                dependencies: dependencies.map { $0.map(\.1) })
            self.module.buffer.append(module)
        }
        return buffer
    }
    // this method leaves `self` in a temporarily-invalid state, as it registers 
    // symbols in the index tables without creating corresponding entries in the 
    // symbol buffer.
    private mutating 
    func register(_ vertex:Vertex, at offset:Int, culture:(id:Module.ID, index:Module.Index)) 
        throws -> Bool
    {
        // about half of the symbols in a typical symbol graph are non-canonical. 
        // (i.e., they are inherited by victims). in theory, these symbols can 
        // recieve documentation through article bindings, but it is very 
        // unlikely that the symbol graph vertices themselves contain 
        // useful information. 
        // 
        // that said, we cannot ignore non-canonical symbols altogether, because 
        // if their canonical base originates from an underscored protocol 
        // (or is implicitly private itself), then the non-canonical symbols 
        // are our only source of information about the canonical base. 
        // 
        // example: UnsafePointer.predecessor() actually originates from 
        // the witness `ss8_PointerPsE11predecessorxyF`, which is part of 
        // the underscored `_Pointer` protocol.
        var symbol:Symbol.Index { .init(culture.index, offset: offset) }
        // FIXME: all vertices can have duplicates, even canonical ones, due to 
        // the behavior of `@_exported import`.
        guard case .synthesized = vertex.kind 
        else 
        {
            if let _:Symbol.Index = self.symbol.indices.updateValue(symbol, forKey: vertex.content.id)
            {
                throw Symbol.CollisionError.init(vertex.content.id, from: culture.id) 
            }
            return true
        }
        // *not* subgraph.namespace !
        guard case nil = self.symbol.indices.index(forKey: vertex.content.id)
        else 
        {
            return false 
        }
        
        // if the symbol is synthetic and belongs to an underscored 
        // protocol, assume the generic base does not exist, and register 
        // the synthesized copy anyway.
        if vertex.content.id.isUnderscoredProtocolMember(from: culture.id)
        {
            print("note: inferred existence of mythical protocol extension member '\(vertex.content.id.string)' (\(vertex.content.id.description))")
            self.symbol.indices.updateValue(symbol, forKey: vertex.content.id)
            return true 
        }
        // if the symbol is unconditionally unavailable, assume the generic 
        // base does not exist (omitted by SymbolGraphGen), and register the 
        // synthesized copy anyway.
        else if case true? = vertex.content.availability.general?.unavailable
        {
            print("note: inferred existence of unconditionally unavailable symbol '\(vertex.content.id.string)' (\(vertex.content.id.description))")
            self.symbol.indices.updateValue(symbol, forKey: vertex.content.id)
            return true 
        }
        else 
        {
            return false 
        }
    }
}
extension Package 
{
    private mutating 
    func register(_ buffer:NodeBuffer, given scopes:[Scope], paths:inout PathTable) throws
    {
        assert(self.symbol.buffer.isEmpty)
        
        self.symbol.buffer.reserveCapacity(buffer.nodes.count)
        for (module, scope):(Module, Scope) in zip(self.module.buffer, scopes)
        {
            assert(module.index == scope.vantage)
            
            for node:Node in buffer.nodes[module.core.offsets]
            {
                self.symbol.buffer.append(try .init(node, namespace: module.index, scope: scope, paths: &paths))
            }
            for colony:Symbol.ColonialRange in module.colonies 
            {
                for node:Node in buffer.nodes[colony.offsets]
                {
                    self.symbol.buffer.append(try .init(node, namespace: colony.namespace, scope: scope, paths: &paths))
                }
            }
            
            print("(\(self.id)) added module '\(module.id)'")
        }
    }
}
