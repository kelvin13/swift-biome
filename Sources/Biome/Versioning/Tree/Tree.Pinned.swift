import SymbolGraphs
import SymbolSource
import URI

extension Tree 
{
    struct Pinned:Sendable 
    {
        let tree:Tree
        let version:Version
        private 
        let fasces:Fasces 
        
        private 
        init(_ tree:Tree, version:Version, fasces:Fasces)
        {
            self.tree = tree
            self.version = version
            self.fasces = fasces
        }
        init(_ tree:Tree, version:Version)
        {
            self.init(tree, version: version, fasces: tree.fasces(through: version))
        }

        var branch:Branch 
        {
            self.tree[self.version.branch]
        }
        var revision:Branch.Revision 
        {
            self.tree[self.version]
        }
        var selector:VersionSelector?
        {
            self.tree.abbreviate(self.version)
        }

        var nationality:Package 
        {
            self.tree.nationality
        }

        var articles:Fasces.Articles
        {
            self.fasces.articles
        }
        var symbols:Fasces.Symbols
        {
            self.fasces.symbols
        }
        var modules:Fasces.Modules
        {
            self.fasces.modules
        }

        var metadata:Fasces.Metadata
        {
            self.fasces.metadata
        }

        var routes:Fasces.Routes 
        {
            self.fasces.routes
        }

        mutating 
        func repin(to version:Version) 
        {
            if version != self.version
            {
                self = .init(self.tree, version: version)       
            }
        }
    }
}

extension Tree.Pinned 
{
    func repinned(to version:Version) -> Self 
    {
        var repinned:Self = self 
            repinned.repin(to: version)
        return repinned
    }
    func repinned(to revisions:[Version.Revision], of branch:Branch, 
        _ body:(Self) throws -> ()) rethrows 
    {
        let trunk:Fasces? = branch.fork.map(self.tree.fasces(through:))
        for revision:Version.Revision in revisions 
        {
            let version:Version = .init(branch.index, revision)
            let fasces:Fasces
            if let trunk:Fasces 
            {
                fasces = .init([branch[...revision]] + trunk)
            }
            else 
            {
                fasces =       [branch[...revision]]
            }
            try body(.init(self.tree, version: version, fasces: _move fasces))
        }
    }
}
extension Tree.Pinned 
{
    func load(local article:Article) -> Article.Intrinsic?
    {
        assert(self.nationality == article.nationality)
        if let position:AtomicPosition<Article> = article.positioned(bisecting: self.articles)
        {
            return self.tree[local: position]
        }
        else 
        {
            return nil
        }
    }
    func load(local symbol:Symbol) -> Symbol.Intrinsic?
    {
        assert(self.nationality == symbol.nationality)
        if let position:AtomicPosition<Symbol> = symbol.positioned(bisecting: self.symbols)
        {
            return self.tree[local: position]
        }
        else 
        {
            return nil
        }
    }
    func load(local module:Module) -> Module.Intrinsic?
    {
        assert(self.nationality == module.nationality)
        if let position:AtomicPosition<Module> = module.positioned(bisecting: self.modules)
        {
            return self.tree[local: position]
        }
        else 
        {
            return nil
        }
    }
}
extension Tree.Pinned 
{
    func metadata(local article:Article) -> Article.Metadata?
    {
        self.fasces.metadata.articles.value(of: .metadata(of: article)) ?? nil
    }
    func metadata(local symbol:Symbol) -> Symbol.Metadata?
    {
        self.fasces.metadata.symbols.value(of: .metadata(of: symbol)) ?? nil
    }
    func metadata(local module:Module) -> Module.Metadata?
    {
        self.fasces.metadata.modules.value(of: .metadata(of: module)) ?? nil
    }
    func metadata(foreign diacritic:Diacritic) -> Overlay.Metadata?
    {
        self.fasces.metadata.overlays.value(of: .metadata(of: diacritic)) ?? nil
    }
}
extension Tree.Pinned 
{
    func exists(_ module:Module) -> Bool
    {
        self.metadata(local: module) != nil
    }
    func exists(_ article:Article) -> Bool
    {
        self.metadata(local: article) != nil 
    }
    func exists(_ symbol:Symbol) -> Bool
    {
        self.metadata(local: symbol) != nil 
    }
    func exists(_ diacritic:Diacritic) -> Bool
    {
        self.metadata(foreign: diacritic) != nil 
    }
    func exists(_ composite:Composite) -> Bool
    {
        composite.compound.map(self.exists(_:)) ?? self.exists(composite.base)
    }
    func exists(_ compound:Compound) -> Bool 
    {
        self.nationality == compound.host.nationality ?
            self.metadata(local: compound.host)?
                .contains(feature: compound) ?? false :
            self.metadata(foreign: compound.diacritic)?
                .contains(feature: compound.base) ?? false
    }
}
extension Tree.Pinned 
{
    func excavate(_ module:Module) -> Version? 
    {
        self.fasces.metadata.modules.latestVersion(of: .metadata(of: module))
        {
            $0 != nil 
        }
    }
    func excavate(_ article:Article) -> Version? 
    {
        self.fasces.metadata.articles.latestVersion(of: .metadata(of: article))
        {
            $0 != nil 
        }
    }
    func excavate(_ symbol:Symbol) -> Version? 
    {
        self.fasces.metadata.symbols.latestVersion(of: .metadata(of: symbol))
        {
            $0 != nil 
        }
    }
    func excavate(_ composite:Composite) -> Version? 
    {
        composite.compound.map(self.excavate(_:)) ?? self.excavate(composite.base)
    }
    func excavate(_ compound:Compound) -> Version? 
    {
        self.nationality == compound.host.nationality ?
        self.fasces.metadata.symbols.latestVersion(of: .metadata(of: compound.host))
        {
            $0?.contains(feature: compound) ?? false 
        }
        :
        self.fasces.metadata.overlays.latestVersion(of: .metadata(of: compound.diacritic))
        {
            $0?.contains(feature: compound.base) ?? false 
        }
    }
}

extension Tree.Pinned 
{
    func resolve(_ link:_SymbolLink, scope:LexicalScope?, stems:Route.Stems, 
        where predicate:(Composite) throws -> Bool) 
        rethrows -> _SymbolLink.Resolution?
    {
        if  let resolution:_SymbolLink.Resolution = try self.resolve(exactly: link, 
                scope: scope, 
                stems: stems, 
                where: predicate)
        {
            return resolution 
        }
        if  let link:_SymbolLink = link.outed, 
            let resolution:_SymbolLink.Resolution = try self.resolve(exactly: link, 
                scope: scope, 
                stems: stems, 
                where: predicate)
        {
            return resolution
        }
        else 
        {
            return nil 
        }
    }
    private 
    func resolve(exactly link:_SymbolLink, scope:LexicalScope?, stems:Route.Stems, 
        where predicate:(Composite) throws -> Bool) 
        rethrows -> _SymbolLink.Resolution?
    {
        if  let scope:LexicalScope, 
            let selection:Selection<Composite> = try scope.scan(concatenating: link, 
                stems: stems, 
                until: { try self.routes.select($0, where: predicate) })
        {
            return .init(selection)
        }
        guard let namespace:AtomicPosition<Module> = self.fasces.modules.find(.init(link.first))
        else 
        {
            return nil
        }
        guard let link:_SymbolLink = link.suffix
        else 
        {
            return .module(namespace.atom)
        }
        if  let key:Route = stems[namespace.atom, link], 
            let selection:Selection<Composite> = try self.routes.select(key, 
                where: predicate)
        {
            return .init(selection)
        }
        else 
        {
            return nil
        }
    }
}

extension Tree.Pinned 
{
    func documentation() -> DocumentationExtension<Never>?
    {
        fatalError("unimplemented")
    }

    func documentation(for symbol:Symbol) -> DocumentationExtension<Symbol>?
    {
        self.fasces.data.symbolDocumentation.value(of: .documentation(of: symbol))
    }
    func documentation(for article:Article) -> DocumentationExtension<Never>?
    {
        self.fasces.data.articleDocumentation.value(of: .documentation(of: article))
    }
    func documentation(for module:Module) -> DocumentationExtension<Never>?
    {
        self.fasces.data.moduleDocumentation.value(of: .documentation(of: module))
    }
    
    func topLevelSymbols(of module:Module) -> Set<Symbol>?
    {
        self.fasces.data.topLevelSymbols.value(of: .topLevelSymbols(of: module))
    }
    func topLevelArticles(of module:Module) -> Set<Article>?
    {
        self.fasces.data.topLevelArticles.value(of: .topLevelArticles(of: module))
    }

    func declaration(for symbol:Symbol) -> Declaration<Symbol>?
    {
        self.fasces.data.declarations.value(of: .declaration(of: symbol))
    }
    
    @available(*, deprecated, renamed: "exists(_:)")
    func contains(_ composite:Composite) -> Bool 
    {
        self.exists(composite)
    }
}

extension Tree.Pinned 
{
    /// Returns the address of the specified composite, if all of its components 
    /// are defined in the provided context.
    func address(of composite:Composite,
        disambiguate:Address.DisambiguationLevel = .minimally, 
        context:some PackageContext) -> Address?
    {
        if let compound:Compound = composite.compound 
        {
            return self.address(of: compound, 
                disambiguate: disambiguate, 
                context: context)
        }
        else 
        {
            return self.address(of: composite.base, 
                disambiguate: disambiguate, 
                context: context)
        }
    }
    func address(of atomic:Symbol,
        disambiguate:Address.DisambiguationLevel = .minimally, 
        context:some PackageContext) -> Address?
    {
        if let symbol:Symbol.Intrinsic = self.load(local: atomic)
        {
            return self.address(of: atomic, symbol: symbol, 
                disambiguate: disambiguate, 
                context: context)
        }
        else 
        {
            return nil
        }
    }
    func address(of compound:Compound,
        disambiguate:Address.DisambiguationLevel = .minimally, 
        context:some PackageContext) -> Address?
    {
        if  let host:Symbol.Intrinsic = context.load(compound.host), 
            let base:Symbol.Intrinsic = context.load(compound.base)
        {
            return self.address(of: compound, host: host, base: base, 
                disambiguate: disambiguate, 
                context: context)
        }
        else 
        {
            return nil
        }
    }

    /// atomic addresses still require a full context, because they can still 
    /// migrate across namespaces.
    func address(of atomic:Symbol, symbol:Symbol.Intrinsic,
        disambiguate:Address.DisambiguationLevel = .minimally, 
        context:some PackageContext) -> Address?
    {
        assert(self.nationality == atomic.nationality)

        var address:Address.Symbolic = .init(path: symbol.path, orientation: symbol.orientation)
        switch disambiguate 
        {
        case .never: 
            break 
        
        case .minimally:
            switch self.depth(of: symbol.route, atomic: atomic)
            {
            case nil: 
                break 
            case .base?: 
                address.base = symbol.id 
            }
        
        case .maximally:
            address.base = symbol.id 
        }
        
        if  symbol.namespace.nationality != atomic.nationality 
        {
            address.nationality = .init(id: self.tree.id, version: self.selector)
        }

        return .init(address, namespace: symbol.namespace, context: context)
    }
    func address(of compound:Compound, host:Symbol.Intrinsic, base:Symbol.Intrinsic,
        disambiguate:Address.DisambiguationLevel = .minimally, 
        context:some PackageContext) -> Address?
    {
        assert(self.nationality == compound.nationality)

        guard let stem:Route.Stem = host.kind.path
        else 
        {
            return nil 
        }

        var path:Path = host.path 
            path.append(base.name)
        
        var address:Address.Symbolic = .init(path: _move path, orientation: base.orientation)
        switch disambiguate 
        {
        case .never: 
            break 
        
        case .minimally:
            switch self.depth(of: .init(host.namespace, stem, base.route.leaf), 
                compound: compound)
            {
            case nil: 
                break 
            case .base?: 
                address.base = base.id 
            case .host?:
                address.base = base.id 
                address.host = host.id 
            }
        
        case .maximally:
            address.base = base.id 
            address.host = host.id 
        }
        
        if  host.namespace.nationality != compound.nationality 
        {
            address.nationality = .init(id: self.tree.id, version: self.selector)
        }

        return .init(address, namespace: host.namespace, context: context)
    }
}

extension Branch 
{
    enum AtomicDepth:Error 
    {
        case base 
    }
    enum CompoundDepth:Error 
    {
        case base 
        case host 
    }
}
extension Tree.Pinned 
{
    private 
    func depth(of route:Route, atomic:Symbol) -> Branch.AtomicDepth?
    {
        do 
        {
            try self.routes.query(route) 
            {
                guard self.exists($0)
                else 
                {
                    return () 
                }
                if $0.base != atomic 
                {
                    throw Branch.AtomicDepth.base 
                }
            }
            return nil  
        }
        catch 
        {
            return .base
        }
    }
    private 
    func depth(of route:Route, compound:Compound) -> Branch.CompoundDepth?
    {
        do 
        {
            var depth:Branch.CompoundDepth? = nil
            try self.routes.query(route) 
            {
                guard self.exists($0)
                else 
                {
                    return () 
                }
                if $0.base != compound.base 
                {
                    depth = .base 
                }
                else if case compound.host? = $0.host
                {
                    return ()
                }
                else 
                {
                    throw Branch.CompoundDepth.host
                }
            }
            return depth 
        }
        catch 
        {
            return .host 
        }
    }
}
