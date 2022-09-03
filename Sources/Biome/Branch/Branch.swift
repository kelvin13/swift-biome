import PackageResolution

enum _Dependency:Sendable 
{
    case available(_Version)
    case unavailable(Branch.ID, String)
}
enum _DependencyError:Error 
{
    case package                                (unavailable:Package.ID)
    case pin                                    (unavailable:Package.ID)
    case version           (unavailable:(Branch.ID, String), Package.ID)
    case module (unavailable:Module.ID, (Branch.ID, String), Package.ID)
    case target (unavailable:Module.ID,  Branch.ID)
}

public 
struct Branch:Identifiable, Sendable 
{
    public 
    enum ID:Hashable, Sendable 
    {
        case master 
        case custom(String)
        case semantic(SemanticVersion)

        init(_ requirement:PackageResolution.Requirement)
        {
            switch requirement 
            {
            case .version(let version): 
                self = .semantic(version)
            case .branch("master"), .branch("main"): 
                self = .master
            case .branch(let name): 
                self = .custom(name)
            }
        }
    }
    // struct Date:Hashable, Sendable 
    // {
    //     var year:UInt16 
    //     var month:UInt16 
    //     var day:UInt16 
    //     var hour:UInt8
    // }
    struct Ring:Sendable 
    {
        //let revision:Int 
        let modules:Module.Offset
        let symbols:Symbol.Offset
        let articles:Article.Offset
    }
    struct Revision:Sendable 
    {
        let hash:String 
        let ring:Ring
        let pins:[Package.Index: _Version]
        var consumers:[Package.Index: Set<_Version>]

        init(hash:String, ring:Ring, pins:[Package.Index: _Version])
        {
            self.hash = hash 
            self.ring = ring 
            self.pins = pins 
            self.consumers = [:]
        }
    }

    public 
    let id:ID
    let index:_Version.Branch

    let fork:_Version?
    var heads:Package.Heads
    private 
    var revisions:[Revision]

    var routes:Table<Route.Key>
    private(set)
    var modules:Buffer<Module>,
        symbols:Buffer<Symbol>,
        articles:Buffer<Article>
    @available(*, deprecated, renamed: "modules")
    private(set)
    var newModules:Buffer<Module>
    {
        _read { yield self.modules }
        _modify { yield &self.modules }
    }
    @available(*, deprecated, renamed: "symbols")
    private(set)
    var newSymbols:Buffer<Symbol>
    {
        _read { yield self.symbols }
        _modify { yield &self.symbols }
    }
    @available(*, deprecated, renamed: "articles")
    private(set)
    var newArticles:Buffer<Article>
    {
        _read { yield self.articles }
        _modify { yield &self.articles }
    }
    @available(*, deprecated, renamed: "modules.overlay")
    private(set) 
    var updatedModules:[Position<Module>: Module.Heads]
    {
        _read { yield self.modules.overlay }
        _modify { yield &self.modules.overlay }
    }
    @available(*, deprecated, renamed: "symbols.overlay")
    private(set) 
    var updatedSymbols:[Position<Symbol>: Symbol._Heads]
    {
        _read { yield self.symbols.overlay }
        _modify { yield &self.symbols.overlay }
    }
    @available(*, deprecated, renamed: "articles.overlay")
    private(set) 
    var updatedArticles:[Position<Article>: Article.Heads]
    {
        _read { yield self.articles.overlay }
        _modify { yield &self.articles.overlay }
    }
    
    var startIndex:_Version.Revision 
    {
        .init(.init(self.revisions.startIndex))
    }
    var endIndex:_Version.Revision 
    {
        .init(.init(self.revisions.endIndex))
    }
    var indices:Range<_Version.Revision> 
    {
        self.startIndex ..< self.endIndex
    }
    subscript(revision:_Version.Revision) -> Revision
    {
        _read 
        {
            yield  self.revisions[.init(revision.index)]
        }
        _modify
        {
            yield &self.revisions[.init(revision.index)]
        }
    }

    init(id:ID, index:_Version.Branch, fork:(version:_Version, ring:Ring)?)
    {
        self.id = id 
        self.index = index 

        self.fork = fork?.version
        self.heads = .init() 
        self.revisions = []
        
        self.routes = [:]
        self.modules = .init(startIndex: fork?.ring.modules ?? 0)
        self.symbols = .init(startIndex: fork?.ring.symbols ?? 0)
        self.articles = .init(startIndex: fork?.ring.articles ?? 0)
    }
    
    subscript(range:PartialRangeThrough<_Version.Revision>) -> Fascis 
    {
        let ring:Ring = self[range.upperBound].ring
        return .init(branch: self.index,
            routes: self.routes[range], 
            modules: self.modules[..<ring.modules], 
            symbols: self.symbols[..<ring.symbols], 
            articles: self.articles[..<ring.articles])
    }
    subscript(_:UnboundedRange) -> Fascis 
    {
        return .init(branch: self.index, 
            routes: self.routes[...],
            modules: self.modules[...],
            symbols: self.symbols[...],
            articles: self.articles[...])
    }

    mutating 
    func commit(_ hash:String, pins:[Package.Index: _Version]) -> _Version
    {
        let commit:_Version.Revision = self.endIndex
        self.revisions.append(.init(hash: hash, 
            ring: .init(
                modules: self.modules.endIndex, 
                symbols: self.symbols.endIndex, 
                articles: self.articles.endIndex), 
            pins: pins))
        return .init(self.index, commit)
    }

    // FIXME: this could be made a lot more efficient
    func find(_ hash:String) -> _Version.Revision?
    {
        for revision:_Version.Revision in self.indices
        {
            if self[revision].hash == hash 
            {
                return revision 
            }
        }
        return nil 
    }

    func position<Element>(_ index:Element.Index) -> Tree.Position<Element> 
        where Element:BranchElement 
    {
        .init(index, branch: self.index)
    }
}

extension Branch 
{
    mutating 
    func add(module id:Module.ID, culture:Package.Index, fasces:[Fascis]) 
        -> Tree.Position<Module>
    {
        if let existing:Tree.Position<Module> = fasces.find(module: id)
        {
            return existing 
        }
        let index:Position<Module> = self.modules.insert(id, culture: culture, 
            Module.init(id:index:))
        return self.position(index)
    }
    mutating 
    func add(graph:SymbolGraph, namespaces:Namespaces, fasces:[Fascis], stems:inout Route.Stems) 
        -> (_Abstractor, [Extension])
    {
        let (articles, _rendered):([Tree.Position<Article>?], [Extension]) = self.addExtensions(from: graph, 
            namespace: namespaces.module, 
            fasces: fasces, 
            stems: &stems)
        let symbols:[Tree.Position<Symbol>?] = self.addSymbols(from: graph, 
            namespaces: namespaces, 
            fasces: fasces, 
            stems: &stems)
        
        assert(symbols.count == graph.vertices.count)

        var abstractor:_Abstractor = .init(symbols: _move symbols, articles: articles, 
            culture: namespaces.culture)
            abstractor.extend(over: graph.identifiers, by: fasces.find(symbol:))
        return (abstractor, _rendered)
    }

    private mutating 
    func addSymbols(from graph:SymbolGraph, namespaces:Namespaces, fasces:[Fascis], 
        stems:inout Route.Stems) 
        -> [Tree.Position<Symbol>?]
    {
        var positions:[Tree.Position<Symbol>?] = []
            positions.reserveCapacity(graph.identifiers.count)
        for (namespace, vertices):(Module.ID, ArraySlice<SymbolGraph.Vertex<Int>>) in 
            graph.colonies
        {
            // will always succeed for the core subgraph
            guard let namespace:Position<Module> = namespaces.linked[namespace]?.contemporary
            else 
            {
                print("warning: ignored colonial symbolgraph '\(graph.id)@\(namespace)'")
                print("note: '\(namespace)' is not a known dependency of '\(graph.id)'")

                positions.append(contentsOf: repeatElement(nil, count: vertices.count))
                continue 
            }
            
            let start:Symbol.Offset = self.symbols.endIndex
            for (offset, vertex):(Int, SymbolGraph.Vertex<Int>) in 
                zip(vertices.indices, vertices)
            {
                positions.append(self.addSymbol(graph.identifiers[offset], 
                    culture: namespaces.culture, 
                    fasces: fasces, 
                    namespace: namespace, 
                    community: vertex.community, 
                    path: vertex.path, 
                    stems: &stems))
            }
            let end:Symbol.Offset = self.symbols.endIndex 
            if start < end
            {
                let colony:Module.Colony = .init(namespace: namespace, range: start ..< end)
                if self.index == namespaces.module.position.branch 
                {
                    self.modules[contemporary: namespaces.culture].heads.symbols
                        .append(colony)
                }
                else 
                {
                    self.modules.overlay[namespaces.culture, default: .init()].symbols
                        .append(colony)
                }
            }
        }
        return positions
    }
    private mutating 
    func addSymbol(_ id:Symbol.ID, culture:Position<Module>, fasces:[Fascis], 
        namespace:Position<Module>, 
        community:Community, 
        path:Path, 
        stems:inout Route.Stems)
        -> Tree.Position<Symbol>
    {
        if let existing:Tree.Position<Symbol> = fasces.find(symbol: id)
        {
            guard existing.contemporary.module == culture 
            else 
            {
                // swift encodes module names in symbol identifiers, so if a symbol changes culture, 
                // something really weird has happened.
                fatalError("symbol with id '\(id)' has already been registered in a different module! symbolgraph may have been corrupted!")
            }
            return existing 
        }
        let index:Symbol.Index = self.symbols.insert(id, culture: culture)
        {
            (id:Symbol.ID, _:Symbol.Index) in 
            let route:Route.Key = .init(namespace, 
                        stems.register(components: path.prefix), 
                .init(stems.register(component:  path.last), 
                orientation: community.orientation))
            // if the symbol could inherit features, generate a stem 
            // for its children from its full path. this stem will only 
            // go to waste if a concretetype is completely uninhabited, 
            // which is very rare.
            let kind:Symbol.Kind 
            switch community
            {
            case .associatedtype: 
                kind = .associatedtype 
            case .concretetype(let concrete): 
                kind = .concretetype(concrete, path: path.prefix.isEmpty ? 
                    route.leaf.stem : stems.register(components: path))
            case .callable(let callable): 
                kind = .callable(callable)
            case .global(let global): 
                kind = .global(global)
            case .protocol: 
                kind = .protocol 
            case .typealias: 
                kind = .typealias
            }
            return .init(id: id, path: path, kind: kind, route: route)
        }
        return self.position(index)
    }

    // TODO: ideally we want to be rendering markdown AOT. so once that is implemented 
    // in the `SymbolGraphs` module, we can get rid of the ugly tuple return here.
    private mutating 
    func addExtensions(from graph:SymbolGraph, namespace:Namespace, fasces:[Fascis], 
        stems:inout Route.Stems) 
        -> ([Tree.Position<Article>?], [Extension])
    {
        let _extensions:[Extension] = graph.extensions.map
        {
            .init(markdown: $0.source, name: $0.name)
        }

        var positions:[Tree.Position<Article>?] = []
            positions.reserveCapacity(graph.extensions.count)
        let start:Article.Offset = self.articles.endIndex
        for article:Extension in _extensions
        {
            switch (article.metadata.path, article.binding)
            {
            case    (.explicit(let path)?, _), 
                    (.implicit(let path)?, nil):
                // articles are always associated with modules, and the name
                // of that module is part of the article identity.
                positions.append(self.addArticle(.init(namespace.id, path), 
                    culture: namespace.culture, 
                    fasces: fasces, 
                    stems: &stems))
            
            case    (.implicit(_)?, _?), (nil, _): 
                positions.append(nil)
            }
        }
        let end:Article.Offset = self.articles.endIndex
        if start < end
        {
            if self.index == namespace.position.branch 
            {
                self.modules[contemporary: namespace.culture].heads.articles
                    .append(start ..< end)
            }
            else 
            {
                self.modules.overlay[namespace.culture, default: .init()].articles
                    .append(start ..< end)
            }
        }
        return (positions, _extensions)
    }
    private mutating 
    func addArticle(_ id:Article.ID, culture:Position<Module>, fasces:[Fascis], 
        stems:inout Route.Stems)
        -> Tree.Position<Article>
    {
        if let existing:Tree.Position<Article> = fasces.find(article: id)
        {
            guard existing.contemporary.module == culture 
            else 
            {
                fatalError("unreachable")
            }
            return existing 
        }
        let index:Article.Index = self.articles.insert(id, culture: culture)
        {
            (id:Article.ID, index:Article.Index) in 
            // article namespace is always its culture. 
            let route:Route.Key = .init(index.module, 
                        stems.register(components: id.path.prefix), 
                .init(stems.register(component:  id.path.last), 
                orientation: .straight))
            return .init(id: id, route: route)
        }
        return self.position(index)
    }
}

extension Branch 
{
    mutating 
    func inferScopes(_ beliefs:inout Beliefs, lenses:[Lens], stems:Route.Stems)
    {
        let lenses:[Branch.Position<Module>: Lens] = .init(uniqueKeysWithValues: 
            lenses.map { ($0.culture, $0) })
        for index:Dictionary<Tree.Position<Symbol>, Symbol.Facts<Tree.Position<Symbol>>>.Index in 
            beliefs.facts.indices
        {
            guard let contemporary:Position<Symbol> = self.index.idealize(beliefs.facts.keys[index])
            else 
            {
                // only perform inference for contemporary symbols. 
                continue 
            }
            if let shape:Symbol.Shape<Tree.Position<Symbol>> = beliefs.facts.values[index].shape 
            {
                // already have a shape from a member or requirement belief
                self.symbols[contemporary: contemporary].shape = shape
                continue 
            }

            let symbol:Symbol = self.symbols[contemporary: contemporary]
            guard  case nil = symbol.shape, 
                    let scope:Path = .init(symbol.path.prefix), 
                    let lens:Lens = lenses[contemporary.culture]
            else 
            {
                continue 
            }
            // attempt to re-parent this symbol using lexical lookup
            if  let scope:Route.Key = stems[symbol.route.namespace, scope],
                case .one(let scope)? = lens.select(local: scope), 
                let scope:Tree.Position<Symbol> = scope.natural.flatMap(lens.fasces.pluralize(_:))
            {
                self.symbols[contemporary: contemporary].shape = .member(of: scope)
                let member:Tree.Position<Symbol> = beliefs.facts.keys[index]
                if  scope.contemporary.culture == contemporary.culture 
                {
                    beliefs.facts[scope]?.predicates.primary
                        .members.insert(member)
                }
                else 
                {
                    beliefs.facts[scope]?.predicates.accepted[contemporary.culture, default: .init()]
                        .members.insert(member)
                }
            }
            else 
            {
                print("warning: orphaned symbol \(symbol)")
                continue 
            }
        }
    }
}

extension Branch
{
    mutating 
    func add<Versioned>(min value:Versioned, 
        revision:_Version.Revision, 
        fasces:[Fascis], 
        symbol:Position<Symbol>, 
        field:WritableKeyPath<Symbol._Heads, Head<Versioned>?>, 
        to history:inout _History<Versioned>)
        where Versioned:Equatable
    {
        guard symbol.offset < self.symbols.startIndex 
        else 
        {
            // symbol is contemporary to this branch. 
            history.add(min: value, revision: revision, 
                to: &self.symbols[contemporary: symbol]._heads[keyPath: field])
            return 
        }
        for fascis:Fascis in fasces 
        {
            if let head:Head<Versioned> = fascis.symbols.overlay[symbol]?[keyPath: field]
            {
                fatalError("unimplemented")
            }
            guard symbol.offset < fascis.symbols.startIndex 
            else 
            {
                break
            }
        }
    }
}