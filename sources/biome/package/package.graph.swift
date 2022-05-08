import Resource

extension Package 
{
    public 
    struct Catalog<Location>
    {
        public 
        let id:ID 
        public 
        let modules:[Module.Catalog<Location>]
        
        func load(with loader:(Location, Resource.Text) async throws -> Resource) 
            async throws -> [Module.Graph]
        {
            var graphs:[Module.Graph] = []
            for module:Module.Catalog<Location> in self.modules 
            {
                graphs.append(try await module.load(with: loader))
            }
            return graphs
        }
    }
    
    typealias Opinion = (symbol:Symbol.Index, has:Symbol.ExtrinsicRelationship)
    
    struct Graph 
    {
        struct Node 
        {
            var vertex:Vertex.Content
            var legality:Symbol.Legality
            var relationships:[Symbol.Relationship]
            
            init(_ vertex:Vertex)
            {
                self.vertex = vertex.content 
                self.legality = .documented(comment: vertex.comment)
                self.relationships = []
            }
        }
        
        let package:(id:ID, index:Index)
        
        private 
        var nodes:[Node]
        private(set)
        var opinions:[Package.Index: [Opinion]],
            modules:[Module.ID: Module.Index],
            symbols:[Symbol.ID: Symbol.Index]
        
        init(id:ID, index:Index) 
        {
            self.package = (id, index) 
            self.nodes = []
            self.opinions = [:]
            self.symbols = [:]
            self.modules = [:]
        }
    }
}
extension Package.Graph 
{
    // for now, we can only call this *once*!
    // TODO: implement progressive supergraph updates 
    mutating 
    func linearize(_ graphs:[Module.Graph], given ecosystem:Ecosystem, paths:inout PathTable) 
        throws -> (modules:[Module], symbols:[Symbol])
    {
        self.modules = .init(uniqueKeysWithValues: graphs.enumerated().map 
        {
            ($0.1.core.namespace, .init(self.package.index, offset: $0.0))
        })
        
        let modules:[Module]      = try self.populate     (from: graphs, given: ecosystem)
        let scopes:[Module.Scope] = try self.link(modules, from: graphs, given: ecosystem)
        
        var symbols:[Symbol] = []
            symbols.reserveCapacity(self.nodes.count)
        for (module, scope):(Module, Module.Scope) in zip(modules, scopes)
        {
            for node:Node in self.nodes[module.core.offsets]
            {
                symbols.append(try .init(node, namespace: module.index, scope: scope, paths: &paths))
            }
            for colony:Symbol.ColonialRange in module.colonies 
            {
                for node:Node in self.nodes[colony.offsets]
                {
                    symbols.append(try .init(node, namespace: colony.namespace, scope: scope, paths: &paths))
                }
            }
        }
        return (modules, symbols)
    }

    private mutating 
    func populate(from graphs:[Module.Graph], given ecosystem:Ecosystem) throws -> [Module]
    {
        try graphs.indices.map
        {
            (offset:Int) in 
            
            let graph:Module.Graph = graphs[offset]
            let module:(id:Module.ID, index:Module.Index) = 
            (
                id: graph.core.namespace, 
                index: .init(self.package.index, offset: offset)
            )
            
            let dependencies:[[(Module.ID, Module.Index)]] = try graph.dependencies.map 
            {
                (dependency:Module.Graph.Dependency) in 
                
                guard let local:[Module.ID: Module.Index] = dependency.package == self.package.id ? 
                    self.modules : ecosystem[dependency.package]?.indices.modules 
                else 
                {
                    throw Package.ResolutionError.undefined(dependency.package)
                }
                return try dependency.modules.map 
                {
                    guard let index:Module.Index = local[$0] 
                    else 
                    {
                        throw Module.ResolutionError.undefined($0)
                    }
                    return ($0, index)
                }
            }
            //  all of a module’s dependencies have unique names, so build a lookup 
            //  table for them. this lookup table enables this function to 
            //  run in quadratic time; otherwise it would be cubic!
            let bystanders:[Module.ID: Module.Index] = .init(uniqueKeysWithValues: dependencies.joined())

            let core:Symbol.IndexRange = 
                .init(module.index, offsets: try self.populate(module, from: graph.core))
            let colonies:[Symbol.ColonialRange] = try graph.colonies.compactMap
            {
                if let bystander:Module.Index = bystanders[$0.namespace]
                {
                    return .init(namespace: bystander, offsets: try self.populate(module, from: $0))
                }
                else 
                {
                    print("warning: module \(graph.core.namespace) extends \($0.namespace), which is not one of its dependencies")
                    print("warning: skipped subgraph \(graph.core.namespace)@\($0.namespace)")
                    return nil
                }
            }
            let toplevel:[Symbol.Index] = core.filter 
            {
                // a vertex is top-level if it has exactly one path component. 
                self.nodes[$0.offset].vertex.path.count == 1
            }
            return .init(
                id: graph.core.namespace, 
                core: core, 
                colonies: colonies, 
                toplevel: toplevel, 
                dependencies: dependencies.map { $0.map(\.1) })
        }
    }
    private mutating 
    func populate(_ perpetrator:(id:Module.ID, index:Module.Index), from subgraph:Module.Subgraph) 
        throws -> Range<Int>
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
        let start:Int = self.nodes.endIndex
        for vertex:Vertex in subgraph.vertices 
        {
            let symbol:Symbol.Index = .init(perpetrator.index, offset: self.nodes.endIndex)
            // FIXME: all vertices can have duplicates, even canonical ones, due to 
            // the behavior of `@_exported import`.
            if case .natural = vertex.kind 
            {
                if let _:Symbol.Index = self.symbols.updateValue(symbol, forKey: vertex.content.id)
                {
                    throw Symbol.CollisionError.init(vertex.content.id, from: perpetrator.id) 
                }
                self.nodes.append(.init(vertex))
            }
            // *not* subgraph.namespace !
            else if case nil = self.symbols.index(forKey: vertex.content.id), 
                vertex.content.id.isUnderscoredProtocolExtensionMember(from: perpetrator.id)
            {
                // if the symbol is synthetic and belongs to an underscored 
                // protocol, assume the generic base does not exist, and register 
                // it *once*.
                self.symbols.updateValue(symbol, forKey: vertex.content.id)
                self.nodes.append(.init(vertex))
            }
        }
        return start ..< self.nodes.endIndex
    }
    
    private 
    subscript(vertex:Symbol.Index) -> Node?
    {
        self.package.index == vertex.module.package ? self.nodes[vertex.offset] : nil
    }
    
    private mutating 
    func link(_ modules:[Module], from graphs:[Module.Graph], given ecosystem:Ecosystem) 
        throws -> [Module.Scope]
    {
        try zip(modules, graphs).map
        {
            let (module, graph):(Module, Module.Graph) = $0
            
            // compute scope 
            let filter:Set<Module.Index> = ([module.index] as Set).union(module.dependencies.joined())
            let scope:Module.Scope = .init(filter: filter, layers: 
                Set<Package.Index>.init(filter.map(\.package)).map 
            {
                $0 == self.package.index ? self.symbols : ecosystem[$0].indices.symbols
            })
            
            for edge:Edge in graph.edges.joined()
            {
                let constraints:[Generic.Constraint<Symbol.Index>] = try edge.constraints.map
                {
                    try $0.map(scope.index(of:))
                }
                let index:(source:Symbol.Index, target:Symbol.Index) = 
                (
                    source: try scope.index(of: edge.source),
                    target: try scope.index(of: edge.target)
                )
                let color:(source:Symbol.Color, target:Symbol.Color) = 
                (
                    source: self[index.source]?.vertex.color ?? ecosystem[index.source].color,
                    target: self[index.target]?.vertex.color ?? ecosystem[index.target].color
                )
                
                let relationship:(source:Symbol.Relationship?, target:Symbol.Relationship) = 
                    try edge.kind.relationships((index.source, color.source), (index.target, color.target), where: constraints)
                
                try self.link(index.target, relationship.target, accordingTo: module.index)
                if let relationship:Symbol.Relationship = relationship.source 
                {
                    try self.link(index.source, relationship, accordingTo: module.index)
                }
                
                if let fake:Symbol.Index = try edge.fake.map(scope.index(of:))
                {
                    if index.source.module == module.index 
                    {
                        self.deport(index.source, impersonating: fake, given: ecosystem)
                    }
                    else 
                    {
                        // cannot deport symbols from another module
                        throw Symbol.RelationshipError.jurisdiction(module.index, says: index.source, impersonates: fake)
                    }
                }
            }
            
            return scope
        }
    }
    private mutating 
    func link(_ symbol:Symbol.Index, _ relationship:Symbol.Relationship, 
        accordingTo perpetrator:Module.Index) throws
    {
        switch relationship
        {
        case  .is(let intrinsic):
            if perpetrator == symbol.module
            {
                self.nodes[symbol.offset].relationships.append(relationship)
            }
            else 
            {
                throw Symbol.RelationshipError.miscegenation(perpetrator, says: symbol, is: intrinsic)
            }
        
        case .has(let extrinsic):
            if self.package.index == symbol.module.package
            {
                self.nodes[symbol.offset].relationships.append(relationship)
            }
            else 
            {
                self.opinions[symbol.module.package, default: []].append((symbol, has: extrinsic))
            }
        }
    }
    private mutating 
    func deport(_ symbol:Symbol.Index, impersonating citizen:Symbol.Index, given ecosystem:Ecosystem)
    {
        guard case .documented(comment: let papers) = self.nodes[symbol.offset].legality 
        else 
        {
            // symbol has already been deported 
            return 
        }
        switch (self[citizen]?.legality ?? ecosystem[citizen].legality, papers)
        {
        case (.undocumented(impersonating: _), _):
            // this is dangerous because it could cause infinite recursion 
            // if the migration chain forms a cycle!
            // self.deport(symbol, impersonating: citizen, given: biome)
            fatalError("unimplemented")
        
        case (.documented(comment:      _), ""):
            // symbol had no documentation. deport immediately!
            fallthrough
        case (.documented(comment: papers),  _): 
            // symbol had documentation, but it was fradulent. deport immediately!
            self.nodes[symbol.offset].legality = .undocumented(impersonating: citizen)
        
        case (.documented(comment:      _),  _):
            // a small number of symbols using fakes are actually documented, 
            // and should not be deported. 
            print("warning: recovered documentation for symbol \(self.nodes[symbol.offset].vertex.path)")
        }
    }
}
