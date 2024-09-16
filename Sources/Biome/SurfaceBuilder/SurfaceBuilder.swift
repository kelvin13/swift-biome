import SymbolGraphs
import SymbolSource

extension SurfaceBuilder 
{
    fileprivate 
    struct Node 
    {
        var metadata:Symbol.Metadata
        let element:Symbol 
        var scope:Symbol.Scope?
    }
    fileprivate 
    struct Nodes:RandomAccessCollection
    {
        private 
        var storage:[Node]
        private(set) 
        var indices:[Symbol: Symbols.Index]

        init()
        {
            self.storage = []
            self.indices = [:]
        }

        var symbols:Symbols 
        {
            .init(self.storage)
        }

        var startIndex:Symbols.Index 
        {
            .init(offset: self.storage.startIndex)
        }
        var endIndex:Symbols.Index 
        {
            .init(offset: self.storage.endIndex)
        }
        subscript(index:Symbols.Index) -> Node 
        {
            _read 
            {
                yield  self.storage[index.offset]
            }
            _modify
            {
                yield &self.storage[index.offset]
            }
        }

        mutating 
        func append(_ node:Node)
        {
            self.indices[node.element] = .init(offset: self.storage.endIndex)
            self.storage.append(node)
        }
    }
    struct Symbols:RandomAccessCollection
    {
        struct Index:Strideable 
        {
            let offset:Int 

            @inlinable public
            func advanced(by stride:Int) -> Self 
            {
                .init(offset: self.offset.advanced(by: stride))
            }
            @inlinable public
            func distance(to other:Self) -> Int
            {
                self.offset.distance(to: other.offset)
            }
        }

        fileprivate 
        let nodes:[Node]

        fileprivate 
        init(_ nodes:[Node])
        {
            self.nodes = nodes
        }

        var startIndex:Symbols.Index 
        {
            .init(offset: self.nodes.startIndex)
        }
        var endIndex:Symbols.Index 
        {
            .init(offset: self.nodes.endIndex)
        }
        subscript(index:Symbols.Index) -> (Symbol, Symbol.Metadata) 
        {
            let node:Node = self.nodes[index.offset]
            return (node.element, node.metadata)
        }
    }
}

extension SurfaceBuilder
{
    struct Context:Sendable 
    {
        let upstream:[Package: Tree.Pinned]
        let local:Tree

        subscript(global position:AtomicPosition<Symbol>) -> Symbol.Intrinsic
        {
            if  let symbol:Symbol.Intrinsic = self.local[position] ?? 
                    self.upstream[position.nationality]?.tree[local: position]
            {
                return symbol
            }
            else 
            {
                fatalError("unreachable: SurfaceBuilder.Context does not contain requested package (index: \(position.nationality))")
            }
        }
    }
}
extension SurfaceBuilder.Context
{
    fileprivate 
    func validate(edges:[SymbolGraph.Edge<Int>], positions:ModuleInterface.SymbolPositions) 
        -> (beliefs:[SurfaceBuilder.Belief], errors:[any Error])
    {
        var errors:[any Error] = []
        // if we have `n` edges, we will get between `n` and `2n` beliefs
        var beliefs:[SurfaceBuilder.Belief] = []
            beliefs.reserveCapacity(edges.count)
        for edge:SymbolGraph.Edge<Int> in edges
        {
            do 
            {
                let edge:SymbolGraph.Edge<AtomicPosition<Symbol>> = try edge.map 
                {
                    if let position:AtomicPosition<Symbol> = positions[$0]
                    {
                        return position
                    }
                    else 
                    {
                        throw ModuleInterface.SymbolLookupError.init($0)
                    }
                }
                beliefs.append(contentsOf: try .init(edge: edge,
                    source: self[global: edge.source].shape,
                    target: self[global: edge.target].shape))
            } 
            catch let error 
            {
                errors.append(error)
                continue
            }
        }
        return (beliefs, errors)
    }
}

struct SurfaceBuilder 
{
    private(set)
    var previous:
    (
        articles:Set<Article>,
        symbols:Set<Symbol>,
        modules:Set<Module>,
        overlays:Set<Diacritic>
    )
    private(set)
    var routes:Routes

    private(set)
    var articles:[(Article, Article.Metadata)], 
        overlays:[(Diacritic, Overlay.Metadata)], 
        modules:[Module]
    private 
    var nodes:Nodes

    var symbols:Symbols 
    {
        self.nodes.symbols
    }
    
    init(previous:Surface)
    {
        self.previous = 
        (
            .init(previous.articles),
            .init(previous.symbols),
            .init(previous.modules),
            .init(previous.overlays)
        )
        self.routes = .init() 

        self.articles = []
        self.overlays = []
        self.modules = []

        self.nodes = .init()
    }

    mutating 
    func update(with edges:[SymbolGraph.Edge<Int>], 
        interface:ModuleInterface, 
        local:Tree) 
    {
        assert(interface.nationality == local.nationality)

        self.previous.modules.remove(interface.culture)
        self.modules.append(interface.culture)

        for (article, _cached):(AtomicPosition<Article>?, Extension) in 
            zip(interface.articles, interface._cachedMarkdown)
        {
            if let article:AtomicPosition<Article>
            {
                self.previous.articles.remove(article.atom)
                self.articles.append((article.atom, .init(_extension: _cached)))
            }
        }
        
        let context:Context = .init(upstream: interface.context.upstream, local: local)
        
        let (beliefs, errors):([Belief], [any Error]) = context.validate(edges: edges, 
            positions: interface.symbols)
        
        if !errors.isEmpty 
        {
            print("warning: dropped \(errors.count) edges")
        }

        self.insert(_move beliefs, symbols: interface.citizens, context: context)
    }

    private mutating 
    func insert(_ beliefs:__owned [Belief], symbols:ModuleInterface.SymbolCitizens,
        context:Context) 
    {
        var external:[AtomicPosition<Symbol>: [Trait]] = [:]
        var traits:[AtomicPosition<Symbol>: [Trait]] = [:]
        var roles:[AtomicPosition<Symbol>: [Role<AtomicPosition<Symbol>>]] = [:]
        for belief:Belief in beliefs 
        {
            switch (symbols.culture == belief.subject.culture, belief.predicate)
            {
            case (false,  .is(_)):
                fatalError("unimplemented")
            case (false, .has(let trait)):
                external[belief.subject, default: []].append(trait)
            case (true,  .has(let trait)):
                traits[belief.subject, default: []].append(trait)
            case (true,   .is(let role)):
                roles[belief.subject, default: []].append(role)
            }
        }

        for position:AtomicPosition<Symbol>? in symbols 
        {
            if let position:AtomicPosition<Symbol>
            {
                assert(symbols.culture == position.culture)

                self.previous.symbols.remove(position.atom)
                self.nodes.append(self.createLocalSurface(for: position, 
                    traits: traits.removeValue(forKey: position) ?? [], 
                    roles: roles.removeValue(forKey: position) ?? [], 
                    context: context))
            }
        }
        guard traits.isEmpty, roles.isEmpty 
        else 
        {
            fatalError("unimplemented")
        }
        for (position, traits):(AtomicPosition<Symbol>, [Trait]) in external
        {
            if  let subject:Symbol.Intrinsic = context.local[position], 
                let index:Symbols.Index = self.nodes.indices[position.atom]
            {
                let diacritic:Diacritic = .init(host: position.atom, 
                    culture: symbols.culture)

                self.nodes[index].metadata.accepted[symbols.culture] = 
                    self.createForeignSurface(for: subject, metadata: self.nodes[index].metadata, 
                        diacritic: diacritic,
                        traits: traits, 
                        context: context)
            }
            else if let pinned:Tree.Pinned = context.upstream[position.nationality],
                    let metadata:Symbol.Metadata = pinned.metadata(local: position.atom)
            {
                let subject:Symbol.Intrinsic = pinned.tree[local: position]
                let diacritic:Diacritic = .init(host: position.atom, 
                    culture: symbols.culture)
                
                let metadata:Overlay.Metadata = .init(traits: 
                    self.createForeignSurface(for: subject, metadata: metadata, 
                        diacritic: diacritic,
                        traits: traits, 
                        context: context))
                
                self.previous.overlays.remove(diacritic)
                self.overlays.append((diacritic, metadata))
            }
            else 
            {
                fatalError("unreachable: host not visible!")
            }
        }
    }

    private mutating 
    func createLocalSurface(for position:AtomicPosition<Symbol>,
        traits:__owned [Trait], 
        roles:__owned [Role<AtomicPosition<Symbol>>], 
        context:Context)
        -> Node 
    {
        let symbol:Symbol.Intrinsic = context.local[local: position]
        var scope:Symbol.Scope? = nil
        // partition relationships buffer 
        var superclass:Symbol? = nil 
        var residuals:[Role<Symbol>] = []
        for role:Role<AtomicPosition<Symbol>> in roles
        {
            switch (scope, role) 
            {
            case  (nil,            .member(of: let type)): 
                scope =            .member(of:     type) 
            case (nil,        .requirement(of: let interface)): 
                scope =       .requirement(of:     interface) 
            
            case (let scope?,      .member(of: let type)):
                guard case         .member(of:     type) = scope 
                else 
                {
                    fatalError("unimplemented")
                }
            case (let scope?, .requirement(of: let interface)): 
                guard case    .requirement(of:     interface) = scope 
                else 
                {
                    fatalError("unimplemented")
                }
                
            case (_,             .subclass(of: let type)): 
                switch superclass
                {
                case nil, type.atom?:
                    superclass = type.atom
                case _?:
                    fatalError("unimplemented")
                }
                
            default: 
                residuals.append(role.map(\.atom))
            }
        }
            
        let roles:Branch.SymbolRoles? = .init(residuals,
            superclass: superclass, 
            scope: scope,
            as: symbol.shape)
        let traits:Traits = .init(traits, as: symbol.shape)
        
        self.routes.atomic.append(symbol.route, element: position.atom)
        if  let routes:CompoundRoutes = .init(host: symbol, 
                diacritic: .init(atomic: position.atom), 
                features: traits.features, 
                context: context)
        {
            self.routes.compound.append(routes)
        }
        
        return .init(metadata: .init(roles: roles, primary: traits.idealized()),
            element: position.atom, 
            scope: scope)
    }
    private mutating 
    func createForeignSurface(for subject:Symbol.Intrinsic, 
        metadata:Symbol.Metadata, 
        diacritic:Diacritic, 
        traits:__owned [Trait], 
        context:Context)
        -> Branch.SymbolTraits
    {
        let traits:Traits = .init(traits, as: subject.shape).subtracting(metadata.primary)

        if  let routes:CompoundRoutes = .init(host: subject, diacritic: diacritic, 
                features: traits.features, 
                context: context)
        {
            self.routes.compound.append(routes)
        }
        return traits.idealized()
    }

    private mutating 
    func add(member:Symbol, to scope:Symbol)
    {
        guard let index:Symbols.Index = self.nodes.indices[scope]
        else 
        {
            return
        }
        if member.culture == scope.culture
        {
            self.nodes[index].metadata.primary.members.insert(member)
        }
        else 
        {
            self.nodes[index].metadata.accepted[member.culture, default: .init()]
                .members.insert(member)
        }
    }
}

extension SurfaceBuilder 
{
    mutating 
    func inferScopes(for branch:inout Branch, fasces:Fasces, stems:Route.Stems)
    {
        self.inferScopes(for: &branch.symbols, 
            routes: fasces.routes(layering: branch.routes, branch: branch.index), 
            stems: stems)
    }
    private mutating 
    func inferScopes(for symbols:inout IntrinsicBuffer<Symbol>, 
        routes:Fasces.AugmentedRoutes, 
        stems:Route.Stems)
    {
        for node:Node in self.nodes
        {
            // we know that every key in ``Surface.symbols`` is part of the current 
            // package, and that they are all part of the current timeline, so it 
            // is safe to compare atomic offsets.
            if node.element.offset < symbols.startIndex
            {
                continue 
            }
            if let scope:Symbol.Scope = node.scope 
            {
                // already have a scope from a member or requirement belief
                symbols[contemporary: node.element].scope = scope
                continue 
            }

            let symbol:Symbol.Intrinsic = symbols[_contemporary: node.element]
            guard   case nil = symbol.scope, 
                    let scope:Path = .init(symbol.path.prefix)
            else 
            {
                continue 
            }
            //  attempt to re-parent this symbol using lexical lookup. 
            //  this is a *very* heuristical process.
            if  let scope:Route = stems[symbol.route.namespace, straight: scope]
            {
                let selection:Selection<AtomicPosition<Symbol>>? = routes.select(scope)
                {
                    (composite:Composite, branch:Version.Branch) in 
                    composite.atom.map { $0.positioned(branch) }
                }
                if case .one(let scope)? = selection 
                {
                    symbols[contemporary: node.element].scope = .member(of: scope)
                    self.add(member: node.element, to: scope.atom) 
                    continue 
                }
            }
            
            print("warning: orphaned symbol \(symbol)")
        }
    }
}

extension SurfaceBuilder 
{
    func surface() -> Surface 
    {
        .init(articles: self.articles.map(\.0),
            symbols: self.nodes.indices.map(\.key),
            modules: self.modules,
            overlays: self.overlays.map(\.0))
    }
}
