import Resource
import Grammar

public 
struct Package:Identifiable, Sendable
{
    enum UpdateError:Error 
    {
        case versionNotIncremented(Version, from:Version)
    }
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
    
    public 
    enum Kind:Hashable, Comparable, Sendable 
    {
        case swift 
        case core
        case community(String)
    }
    
    struct Pin:Hashable, Sendable 
    {
        var culture:Index 
        var version:Version
        
    }
    struct Pins 
    {
        let versions:[Index: Version]
        
        private 
        init(versions:[Index: Version])
        {
            self.versions = versions 
        }
        init<Indices>(dependencies:Indices, _ pin:(Index) throws -> Version) rethrows
            where Indices:Sequence, Indices.Element == Index 
        {
            self.init(versions: .init(uniqueKeysWithValues: try dependencies.map
            {
                (key: $0, value: try pin($0))
            }))
        }
        
        subscript(dependency:Package.Index) -> Version
        {
            self.versions[dependency]!
        }
        subscript(dependency:Module.Index) -> Version
        {
            self.versions[dependency.package]!
        }
    }
    
    struct Heads 
    {
        @Keyframe<Documentation>.Head
        var documentation:Keyframe<Documentation>.Buffer.Index?
        
        init() 
        {
            self._documentation = .init()
        }
    }
    
    public 
    let id:ID
    let index:Index
    
    var pin:Pin 
    {
        .init(culture: self.index, version: self.latest)
    }
    
    private
    var heads:Heads
    // private 
    // var tag:Resource.Tag?
    private(set)
    var latest:Version
    private(set) 
    var modules:CulturalBuffer<Module.Index, Module>, 
        symbols:CulturalBuffer<Symbol.Index, Symbol>,
        articles:CulturalBuffer<Article.Index, Article>
    private(set)
    var dependencies:Keyframe<Set<Module.Index>>.Buffer, 
        declarations:Keyframe<Symbol.Declaration>.Buffer, 
        relationships:Keyframe<Symbol.Relationships>.Buffer,
        documentation:Keyframe<Documentation>.Buffer
        
    fileprivate
    var groups:Symbol.Groups
    
    func lens(_ version:Version?) -> Lexicon.Lens 
    {
        .init(declarations: self.declarations,
            version: version ?? self.latest, 
            master: self.groups.table, 
            doc: self.articles.indices)
    }
    
    var name:String 
    {
        self.id.string
    }
    var kind:Kind 
    {
        self.id.kind
    }
    
    init(id:ID, index:Index)
    {
        self.id = id 
        self.index = index
        
        self.heads = .init()
        
        // self.tag = "2.0.0"
        self.latest = .tag(0, (0, (0, 0)))
        self.groups = .init()
        self.modules = .init()
        self.symbols = .init()
        self.articles = .init()
        
        self.dependencies = .init()
        self.declarations = .init()
        self.relationships = .init()
        self.documentation = .init()
    }

    subscript(local module:Module.Index) -> Module 
    {
        _read 
        {
            yield self.modules[local: module]
        }
    }
    subscript(local symbol:Symbol.Index) -> Symbol
    {
        _read 
        {
            yield self.symbols[local: symbol]
        }
    } 
    
    subscript(module:Module.Index) -> Module?
    {
        self.index ==        module.package ? self[local: module] : nil
    }
    subscript(symbol:Symbol.Index) -> Symbol?
    {
        self.index == symbol.module.package ? self[local: symbol] : nil
    }
    
    func documentation(forLocal symbol:Symbol.Index, at version:Version)
        -> Keyframe<Documentation>.Buffer.Index?
    {
        self.documentation.find(version, head: self[local: symbol].heads.documentation)
    }
            
    mutating 
    func assign(stereotype:[Symbol.Index: [Symbol.Trait]], from pin:Pin)
    {
        for (symbol, traits):(Symbol.Index, [Symbol.Trait]) in stereotype 
        {
            self.symbols[local: symbol].assign(traits: traits, from: pin)
        }
    }
}

extension Ecosystem 
{
    // also updates the symbol groups
    mutating 
    func updateFeatures(in index:Package.Index, ideology:[Module.Index: Module.Beliefs])
    {
        for (culture, beliefs):(Module.Index, Module.Beliefs) in ideology 
        {
            for (host, relationships):(Symbol.Index, Symbol.Relationships) in beliefs.facts
            {
                assert(host.module.package == index)
                
                let symbol:Symbol = self[host]
                
                self[index].groups.insert(natural: host, at: symbol.route)
                
                guard let path:Route.Stem = symbol.kind.path
                else 
                {
                    continue 
                }
                for (perpetrator, features):(Module.Index?, Set<Symbol.Index>) in 
                    relationships.featuresAssumingConcreteType()
                {
                    self[index].groups.insert(
                        diacritic: .init(victim: host, culture: perpetrator ?? culture), 
                        features: features.map { ($0, self[$0].route.leaf) }, 
                        under: (symbol.namespace, path))
                }
            }
            for (victim, traits):(Symbol.Index, [Symbol.Trait]) in beliefs.opinions.values.joined()
            {
                assert(victim.module.package != index)
                
                let symbol:Symbol = self[victim]
                
                guard let path:Route.Stem = symbol.kind.path
                else 
                {
                    // can have external traits that do not have to do with features
                    continue 
                }
                let features:[Symbol.Index] = traits.compactMap(\.feature) 
                if !features.isEmpty
                {
                    self[index].groups.insert(
                        diacritic: .init(victim: victim, culture: culture), 
                        features: features.map { ($0, self[$0].route.leaf) }, 
                        under: (symbol.namespace, path))
                }
            }
        }
        print("(\(self[index].id)) found \(self[index].groups.table.count) addressable endpoints")
    }
}

extension Package 
{
    mutating 
    func push(version:Version) throws 
    {
        guard self.latest < version
        else 
        {
            throw UpdateError.versionNotIncremented(version, from: self.latest)
        }
        self.latest = version
    }

    mutating 
    func updateDependencies(of cultures:[Module.Index], with dependencies:[Set<Module.Index>])
    {
        for (index, dependencies):(Module.Index, Set<Module.Index>) in zip(cultures, dependencies)
        {
            self.dependencies.update(head: &self.modules[local: index].heads.dependencies, 
                to: self.latest, with: dependencies)
        }
    }
    
    mutating 
    func updateDeclarations(scopes:[Symbol.Scope], symbols:[[Symbol.Index: Vertex.Frame]]) 
        throws -> [Dictionary<Symbol.Index, Symbol.Declaration>.Keys]
    {
        let declarations:[[Symbol.Index: Symbol.Declaration]] = try zip(scopes, symbols).map
        {
            let (scope, symbols):(Symbol.Scope, [Symbol.Index: Vertex.Frame]) = $0
            return try symbols.mapValues { try .init($0, scope: scope) }
        }
        self.update(declarations: declarations)
        return declarations.map(\.keys)
    }
    private mutating 
    func update(declarations:[[Symbol.Index: Symbol.Declaration]]) 
    {
        for (index, declaration):(Symbol.Index, Symbol.Declaration) in declarations.joined() 
        {
            self.declarations.update(head: &self.symbols[local: index].heads.declaration, 
                to: self.latest, with: declaration)
        }
    }
    
    mutating 
    func updateRelationships(ideology:[Module.Index: Module.Beliefs]) -> Ecosystem.Opinions 
    {
        self.update(relationships: ideology.values.map(\.facts))
        // merge opinions into a single dictionary
        return ideology.values.reduce(into: [:])
        {
            $0.merge($1.opinions) { $0.merging($1, uniquingKeysWith: + ) }
        }
    }
    private mutating 
    func update(relationships:[[Symbol.Index: Symbol.Relationships]])
    {
        for (index, relationships):(Symbol.Index, Symbol.Relationships) in relationships.joined()
        {
            self.relationships.update(head: &self.symbols[local: index].heads.relationships, 
                to: self.latest, with: relationships)
        }
    }

    mutating 
    func updateDocumentation(_ compiled:[Link.Target: Documentation])
        -> [Symbol.Index: Keyframe<Documentation>.Buffer.Index]
    {
        var sponsors:[Symbol.Index: Keyframe<Documentation>.Buffer.Index] = [:]
        for (target, documentation):(Link.Target, Documentation) in compiled 
        {
            switch target 
            {
            case .composite(let composite):
                guard case nil = composite.victim 
                else 
                {
                    fatalError("unimplemented")
                }
                self.documentation.update(head: &self.symbols[local: composite.base].heads.documentation, 
                    to: self.latest, with: documentation)
                sponsors[composite.base] = self.symbols[local: composite.base].heads.documentation
                
            case .article(let index): 
                self.documentation.update(head: &self.articles[local: index].heads.documentation, 
                    to: self.latest, with: documentation)
                
            case .module(let index): 
                self.documentation.update(head: &self.modules[local: index].heads.documentation, 
                    to: self.latest, with: documentation)
            case .package(self.index): 
                self.documentation.update(head: &self.heads.documentation, 
                    to: self.latest, with: documentation)
            
            case .package(_): 
                fatalError("unreachable")
            }
        }
        return sponsors
    }
    mutating 
    func distributeDocumentation(_ migrants:[Symbol.Index: Keyframe<Documentation>.Buffer.Index]) 
    {
        for (migrant, sponsor):(Symbol.Index, Keyframe<Documentation>.Buffer.Index) in migrants 
        {
            self.documentation.update(head: &self.symbols[local: migrant].heads.documentation, 
                to: self.latest, with: .shared(sponsor))
        }
    }
}

extension Package 
{
    mutating 
    func addModules(_ graphs:[Module.Graph]) -> [Module.Index]
    {
        graphs.map 
        { 
            self.modules.insert($0.core.namespace, culture: self.index, Module.init(id:index:))
        }
    }
    
    mutating 
    func addExtensions(in cultures:[Module.Index], graphs:[Module.Graph], keys:inout Route.Keys) 
        -> (articles:[[Article.Index: Extension]], extensions:[[String: Extension]])
    {
        var articles:[[Article.Index: Extension]] = []
            articles.reserveCapacity(graphs.count)
        var extensions:[[String: Extension]] = []
            extensions.reserveCapacity(graphs.count)
        for (culture, graph):(Module.Index, Module.Graph) in zip(cultures, graphs)
        {
            let column:(articles:[Article.Index: Extension], extensions:[String: Extension]) =
                self.addExtensions(in: culture, graph: graph, keys: &keys)
            extensions.append(column.extensions)
            articles.append(column.articles)
        }
        return (articles, extensions)
    }
    private mutating 
    func addExtensions(in culture:Module.Index, graph:Module.Graph, keys:inout Route.Keys) 
        -> (articles:[Article.Index: Extension], extensions:[String: Extension])
    {
        var articles:[Article.Index: Extension] = [:]
        var extensions:[String: Extension] = [:] 
        for article:Extension in graph.articles
        {
            if let binding:String = article.binding 
            {
                extensions[binding] = article 
                continue 
            }
            // article namespace is always its culture
            guard let path:Path = article.metadata.path
            else 
            {
                // should have been checked earlier
                fatalError("unreachable")
            }
            let id:Route = .init(culture, 
                      keys.register(components: path.prefix), 
                .init(keys.register(component:  path.last), 
                orientation: .straight))
            let index:Article.Index = self.articles.insert(id, culture: culture)
            {
                (route:Route, _:Article.Index) in 
                .init(path: path, route: route)
            }
            articles[index] = article
        }
        return (articles, extensions)
    }
    
    mutating 
    func addSymbols(through scopes:[Symbol.Scope], graphs:[Module.Graph], keys:inout Route.Keys) 
        -> [[Symbol.Index: Vertex.Frame]]
    {
        let extant:Int = self.symbols.count
        
        let symbols:[[Symbol.Index: Vertex.Frame]] = zip(scopes, graphs).map
        {
            self.addSymbols(through: $0.0, graph: $0.1, keys: &keys)
        }
        
        let updated:Int = symbols.reduce(0) { $0 + $1.count }
        print("(\(self.id)) updated \(updated) symbols (\(self.symbols.count - extant) are new)")
        return symbols
    }
    private mutating 
    func addSymbols(through scope:Symbol.Scope, graph:Module.Graph, keys:inout Route.Keys) 
        -> [Symbol.Index: Vertex.Frame]
    {            
        var updates:[Symbol.Index: Vertex.Frame] = [:]
        for colony:Module.Subgraph in [[graph.core], graph.colonies].joined()
        {
            // will always succeed for the core subgraph
            guard let namespace:Module.Index = scope.namespaces[colony.namespace]
            else 
            {
                print("warning: ignored colonial symbolgraph '\(graph.core.namespace)@\(colony.namespace)'")
                print("note: '\(colony.namespace)' is not a known dependency of '\(graph.core.namespace)'")
                continue 
            }
            
            let offset:Int = self.symbols.count
            for (id, vertex):(Symbol.ID, Vertex) in colony.vertices 
            {
                if scope.contains(id) 
                {
                    // usually happens because of inferred symbols. ignore.
                    continue 
                }
                let index:Symbol.Index = self.symbols.insert(id, culture: scope.culture)
                {
                    (id:Symbol.ID, _:Symbol.Index) in 
                    let route:Route = .init(namespace, 
                              keys.register(components: vertex.path.prefix), 
                        .init(keys.register(component:  vertex.path.last), 
                        orientation: vertex.color.orientation))
                    // if the symbol could inherit features, generate a stem 
                    // for its children from its full path. this stem will only 
                    // go to waste if a concretetype is completely uninhabited, 
                    // which is very rare.
                    let kind:Symbol.Kind 
                    switch vertex.color 
                    {
                    case .associatedtype: 
                        kind = .associatedtype 
                    case .concretetype(let concrete): 
                        kind = .concretetype(concrete, path: vertex.path.prefix.isEmpty ? 
                            route.leaf.stem : keys.register(components: vertex.path))
                    case .callable(let callable): 
                        kind = .callable(callable)
                    case .global(let global): 
                        kind = .global(global)
                    case .protocol: 
                        kind = .protocol 
                    case .typealias: 
                        kind = .typealias
                    }
                    return .init(id: id, path: vertex.path, kind: kind, route: route)
                }
                
                updates[index] = vertex.frame
            }
            
            self.modules[local: scope.culture].matrix.append(Symbol.ColonialRange.init(
                namespace: namespace, offsets: offset ..< self.symbols.count))
        }
        return updates
    }
}
