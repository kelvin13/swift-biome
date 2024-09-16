import SymbolGraphs
import SymbolSource
import Versions
import Sediment

extension Sediment where Instant == Version.Revision, Value:Equatable
{
    fileprivate mutating 
    func deposit<Axis>(inserting value:__owned Value,
        revision:Version.Revision,
        field:FieldAccessor<Axis.Divergence, Value>,
        trunk:some FieldViews<some PeriodAxis<Axis.Divergence>, Value>,
        axis:inout Axis) 
        where Axis:BranchAxis
    {
        let current:OriginalHead<Value>? = axis[field]

        if  let current:OriginalHead<Value>
        {
            guard self[current.index].value != value
            else
            {
                return
            }
        }
        else if let existing:Value = trunk.value(of: field)
        {
            guard existing != value
            else
            {
                return
            }
        }

        axis[field, since: revision] = self.deposit(value, time: revision, over: current)
    }
}

extension Branch
{
    mutating 
    func updateMetadata(interface:PackageInterface, builder:SurfaceBuilder)
    {
        for missing:Module in builder.previous.modules 
        {
            self.history.metadata.modules.deposit(inserting: nil,
                revision: interface.revision, 
                field: .metadata(of: missing), 
                trunk: interface.local.metadata.modules,
                axis: &self.modules)
        }
        for missing:Article in builder.previous.articles 
        {
            self.history.metadata.articles.deposit(inserting: nil,
                revision: interface.revision, 
                field: .metadata(of: missing), 
                trunk: interface.local.metadata.articles,
                axis: &self.articles)
        }
        for missing:Symbol in builder.previous.symbols
        {
            self.history.metadata.symbols.deposit(inserting: nil, 
                revision: interface.revision, 
                field: .metadata(of: missing), 
                trunk: interface.local.metadata.symbols,
                axis: &self.symbols)
        }
        for missing:Diacritic in builder.previous.overlays
        {
            self.history.metadata.overlays.deposit(inserting: nil, 
                revision: interface.revision, 
                field: .metadata(of: missing),
                trunk: interface.local.metadata.overlays,
                axis: &self.overlays)
        }
        
        for module:ModuleInterface in interface
        {
            self.history.metadata.modules.deposit(
                inserting: .init(dependencies: module.namespaces.dependencies()),
                revision: interface.revision, 
                field: .metadata(of: module.culture), 
                trunk: interface.local.metadata.modules,
                axis: &self.modules)
        }
        for (article, metadata):(Article, Article.Metadata) in builder.articles
        {
            self.history.metadata.articles.deposit(
                inserting: metadata,
                revision: interface.revision, 
                field: .metadata(of: article), 
                trunk: interface.local.metadata.articles,
                axis: &self.articles) 
        }
        for (symbol, metadata):(Symbol, Symbol.Metadata) in builder.symbols
        {
            self.history.metadata.symbols.deposit(
                inserting: metadata,
                revision: interface.revision, 
                field: .metadata(of: symbol), 
                trunk: interface.local.metadata.symbols,
                axis: &self.symbols) 
        }
        for (diacritic, metadata):(Diacritic, Overlay.Metadata) in builder.overlays
        {
            self.history.metadata.overlays.deposit(
                inserting: metadata, 
                revision: interface.revision, 
                field: .metadata(of: diacritic), 
                trunk: interface.local.metadata.overlays,
                axis: &self.overlays)
        }
    }

    mutating 
    func updateTopLevelSymbols(_ topLevelSymbols:__owned Set<Symbol>, 
        interface:ModuleInterface, 
        revision:Version.Revision)
    {
        self.history.data.topLevelSymbols.deposit(
            inserting: topLevelSymbols, 
            revision: revision, 
            field: .topLevelSymbols(of: interface.culture), 
            trunk: interface.local.data.topLevelSymbols,
            axis: &self.modules)
    }
    mutating 
    func updateTopLevelArticles(_ topLevelArticles:__owned Set<Article>, 
        interface:ModuleInterface, 
        revision:Version.Revision)
    {
        self.history.data.topLevelArticles.deposit(
            inserting: topLevelArticles, 
            revision: revision, 
            field: .topLevelArticles(of: interface.culture), 
            trunk: interface.local.data.topLevelArticles,
            axis: &self.modules)
    }
    mutating 
    func updateDeclarations(_ culture:SymbolGraph.Culture, 
        interface:ModuleInterface,
        revision:Version.Revision)
    {
        for (position, declaration):(AtomicPosition<Symbol>?, Declaration<Int>) in 
            zip(interface.citizens, culture.declarations)
        {
            guard let element:Symbol = position?.atom
            else 
            {
                continue 
            }
            let declaration:Declaration<Symbol> = declaration.flatMap 
            {
                interface.symbols[$0]?.atom
            }
            self.history.data.declarations.deposit(inserting: declaration, 
                revision: revision, 
                field: .declaration(of: element),
                trunk: interface.local.data.declarations,
                axis: &self.symbols)
        }
    }

    mutating 
    func updateDocumentation(_ documentation:__owned PackageDocumentation, 
        interface:PackageInterface)
    {
        for (key, documentation):(Module, DocumentationExtension<Never>)
            in documentation.modules 
        {
            self.history.data.standaloneDocumentation.deposit(inserting: documentation, 
                revision: interface.revision, 
                field: .documentation(of: key), 
                trunk: interface.local.data.moduleDocumentation,
                axis: &self.modules)
        }
        for (key, documentation):(Article, DocumentationExtension<Never>)
            in documentation.articles 
        {
            self.history.data.standaloneDocumentation.deposit(inserting: documentation, 
                revision: interface.revision, 
                field: .documentation(of: key), 
                trunk: interface.local.data.articleDocumentation,
                axis: &self.articles)
        }
        for (key, documentation):(Symbol, DocumentationExtension<Symbol>)
            in documentation.symbols 
        {
            self.history.data.cascadingDocumentation.deposit(inserting: documentation, 
                revision: interface.revision, 
                field: .documentation(of: key), 
                trunk: interface.local.data.symbolDocumentation,
                axis: &self.symbols)
        }
    }
}

public 
struct Branch:Identifiable, Sendable 
{
    public 
    let id:Tag
    let index:Version.Branch

    let fork:Version?
    var revisions:Revisions

    var modules:IntrinsicBuffer<Module>,
        articles:IntrinsicBuffer<Article>, 
        symbols:IntrinsicBuffer<Symbol>
    var overlays:OverlayTable
    var routes:RoutingTable

    var history:History

    init(id:ID, index:Version.Branch, fork:(version:Version, ring:Ring)?)
    {
        self.id = id 
        self.index = index 

        self.fork = fork?.version

        self.revisions = .init()
        
        self.overlays = .init()
        self.articles = .init(startIndex: fork?.ring.articles ?? 0)
        self.symbols = .init(startIndex: fork?.ring.symbols ?? 0)
        self.modules = .init(startIndex: fork?.ring.modules ?? 0)
        self.routes = .init()

        self.history = .init()
    }

    var head:Version.Revision? 
    {
        self.revisions.indices.last
    }
    var latest:Version? 
    {
        self.head.map { .init(self.index, $0) }
    }
    
    subscript(range:PartialRangeThrough<Version.Revision>) -> Fascis
    {
        let ring:Ring = self.revisions[range.upperBound].ring
        return .init(
            modules: self.modules[..<ring.modules], 
            articles: self.articles[..<ring.articles],
            symbols: self.symbols[..<ring.symbols], 
            overlays: self.overlays,
            history: self.history,
            routes: self.routes, 
            branch: self.index,
            limit: range.upperBound, 
            fork: self.fork)
    }
}
extension Branch 
{
    mutating 
    func commit(_ commit:__owned Commit, token:UInt, 
        pins:__owned [Package: Version]) -> Version
    {
        let revision:Version.Revision = self.revisions.endIndex
        self.revisions.append(.init(commit: commit, token: token,
            ring: .init(
                modules: self.modules.endIndex, 
                symbols: self.symbols.endIndex, 
                articles: self.articles.endIndex), 
            pins: pins))
        return .init(self.index, revision)
    }
    mutating 
    func revert(to previous:Version.Revision)
    {
        let current:Version.Revision = self.revisions.index(after: previous)
        guard current < self.revisions.endIndex 
        else 
        {
            return 
        }

        let ring:Ring = self.revisions[previous].ring
        let rollbacks:History.Rollbacks = self.history.erode(until: previous)

        self.modules.revert(to: rollbacks, through: ring.modules)
        self.symbols.revert(to: rollbacks, through: ring.symbols)
        self.articles.revert(to: rollbacks, through: ring.articles)
        self.overlays.revert(to: rollbacks)
        self.routes.revert(to: previous)

        self.revisions.remove(from: current)
    }
    mutating 
    func revert()
    {
        self.revisions.removeAll()
        self.overlays = .init()
        self.articles.revert()
        self.symbols.revert()
        self.modules.revert()
        self.routes = .init()
        self.history = .init()
    }
}
extension Branch 
{
    mutating 
    func addModule(_ namespace:ModuleIdentifier, nationality:Package, local:Fasces) 
        -> AtomicPosition<Module>
    {
        if let existing:AtomicPosition<Module> = local.modules.find(namespace)
        {
            return existing 
        }
        else 
        {
            return self.modules
                .insert(namespace, group: nationality, 
                    creator: Module.Intrinsic.init(id:culture:))
                .positioned(self.index)
        }
    }

    mutating 
    func addSymbols(from culture:SymbolGraph.Culture, visible:Set<Module>,
        context:ModuleUpdateContext, 
        stems:inout Route.Stems) -> [AtomicPosition<Symbol>?]
    {
        var positions:[AtomicPosition<Symbol>?] = []
            positions.reserveCapacity(culture.count)
        for colony:SymbolGraph.Colony in culture.colonies
        {
            // will always succeed for the core subgraph
            guard let namespace:Module = context.linked[colony.namespace]?.atom
            else 
            {
                print("warning: ignored colonial symbolgraph '\(colony.culture)@\(colony.namespace)'")
                print("note: '\(colony.namespace)' is not a known dependency of '\(colony.culture)'")

                positions.append(contentsOf: repeatElement(nil, count: colony.count))
                continue 
            }
            
            // let start:Symbol.Offset = self.symbols.endIndex
            for (id, intrinsic):(SymbolIdentifier, SymbolGraph.Intrinsic) in colony
            {
                positions.append(self.addSymbol(id, culture: context.culture, 
                    namespace: namespace,
                    intrinsic: intrinsic,
                    visible: visible, 
                    context: context, 
                    stems: &stems))
            }
            // let end:Symbol.Offset = self.symbols.endIndex 
            // if start < end
            // {
            //     if self.index == context.module.branch 
            //     {
            //         self.modules[contemporary: context.culture].symbols
            //             .append((start ..< end, namespace))
            //     }
            //     else 
            //     {
            //         self.modules.divergences[context.culture, default: .init()].symbols
            //             .append((start ..< end, namespace))
            //     }
            // }
        }
        return positions
    }
    private mutating 
    func addSymbol(_ id:SymbolIdentifier, culture:Module, namespace:Module, 
        intrinsic:SymbolGraph.Intrinsic,
        visible:Set<Module>,
        context:ModuleUpdateContext,
        stems:inout Route.Stems)
        -> AtomicPosition<Symbol>
    {
        if let existing:AtomicPosition<Symbol> = context.local.symbols.find(id)
        {
            // swift encodes module names in symbol identifiers, so if a symbol changes culture, 
            // something really weird has happened.
            if existing.culture == culture 
            {
                return existing 
            }
            else 
            {
                fatalError("symbol with id '\(id)' has already been registered in a different module! symbolgraph may have been corrupted!")
            }
        } 
        for upstream:Tree.Pinned in context.upstream.values 
        {
            if  let restated:AtomicPosition<Symbol> = upstream.symbols.find(id), 
                    visible.contains(restated.culture)
            {
                return restated 
            }
        }
        let atom:Symbol = self.symbols.insert(id, group: culture)
        {
            (id:SymbolIdentifier, _:Symbol) in 
            let route:Route = .init(namespace, 
                      stems.register(components: intrinsic.path.prefix), 
                .init(stems.register(component:  intrinsic.path.last), 
                orientation: intrinsic.shape.orientation))
            // if the symbol could inherit features, generate a stem 
            // for its children from its full path. this stem will only 
            // go to waste if a concretetype is completely uninhabited, 
            // which is very rare.
            let kind:Symbol.Kind 
            switch intrinsic.shape
            {
            case .associatedtype: 
                kind = .associatedtype 
            case .concretetype(let concrete): 
                kind = .concretetype(concrete, path: intrinsic.path.prefix.isEmpty ? 
                    route.leaf.stem : stems.register(components: intrinsic.path))
            case .callable(let callable): 
                kind = .callable(callable)
            case .global(let global): 
                kind = .global(global)
            case .protocol: 
                kind = .protocol 
            case .typealias: 
                kind = .typealias
            }
            return .init(id: id, path: intrinsic.path, kind: kind, route: route)
        }
        return atom.positioned(self.index)
    }

    // TODO: ideally we want to be rendering markdown AOT. so once that is implemented 
    // in the `SymbolGraphs` module, we can get rid of the ugly tuple return here.
    mutating 
    func addExtensions(from culture:SymbolGraph.Culture, namespace:AtomicPosition<Module>, 
        trunk:Fasces.Articles, 
        stems:inout Route.Stems) 
        -> ([AtomicPosition<Article>?], [Extension])
    {
        let _extensions:[Extension] = culture.markdown.map
        {
            .init(markdown: $0.source, name: $0.name)
        }

        var positions:[AtomicPosition<Article>?] = []
            positions.reserveCapacity(culture.markdown.count)
        // let start:Article.Offset = self.articles.endIndex
        for article:Extension in _extensions
        {
            switch (article.metadata.path, article.binding)
            {
            case    (.explicit(let path)?, _), 
                    (.implicit(let path)?, nil):
                // articles are always associated with modules, and the name
                // of that module is part of the article identity.
                positions.append(self.addArticle(path, 
                    culture: namespace.atom, 
                    trunk: trunk, 
                    stems: &stems))
            
            case    (.implicit(_)?, _?), (nil, _): 
                positions.append(nil)
            }
        }
        // let end:Article.Offset = self.articles.endIndex
        // if start < end
        // {
        //     if self.index == namespace.branch 
        //     {
        //         self.modules[contemporary: namespace.atom].articles
        //             .append(start ..< end)
        //     }
        //     else 
        //     {
        //         self.modules.divergences[namespace.atom, default: .init()].articles
        //             .append(start ..< end)
        //     }
        // }
        return (positions, _extensions)
    }
    private mutating 
    func addArticle(_ path:Path, culture:Module, trunk:Fasces.Articles, 
        stems:inout Route.Stems)
        -> AtomicPosition<Article>
    {
        // article namespace is always its culture. 
        let stem:Route.Stem = stems.register(components: path.prefix) 
        let leaf:Route.Stem = stems.register(component: path.last)

        let id:Article.Intrinsic.ID = .init(culture, stem, leaf)

        if let existing:AtomicPosition<Article> = trunk.find(id)
        {
            guard existing.culture == culture 
            else 
            {
                fatalError("unreachable")
            }
            return existing 
        }
        let atom:Article = self.articles.insert(id, group: culture)
        {
            (id:Article.Intrinsic.ID, _:Article) in 
            .init(id: id, path: path)
        }
        return atom.positioned(self.index)
    }
}
