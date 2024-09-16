import SymbolSource
import URI

enum Scheme 
{
    case symbol
    case doc
}
struct Resolver 
{
    // these exists to make lookups/iteration easier
    private 
    let linked:[PackageIdentifier: Tree.Pinned]
    let context:DirectionalContext
    let namespaces:Namespaces

    init(local:Tree.Pinned, context:__shared ModuleUpdateContext)
    {
        //let context:DirectionalContext = .init(local: _move local, upstream: context.upstream)
        var linked:[PackageIdentifier: Tree.Pinned] = [:]

        linked.reserveCapacity(context.upstream.count + 1)
        linked[local.tree.id] = local 
        for upstream:Tree.Pinned in context.upstream.values 
        {
            linked[upstream.tree.id] = upstream
        }

        self.namespaces = context.namespaces
        self.context = .init(local: local, upstream: context.upstream)
        self.linked = linked
    }

    var local:Tree.Pinned 
    {
        self.context.local
    }
}
extension Resolver
{
    private
    func select(_ key:Route, disambiguator:_SymbolLink.Disambiguator, 
        imports:Set<Module>) -> Selection<Composite>?
    {
        var selection:Selection<Composite>? = nil 

        func inspect(_ lens:Tree.Pinned)
        {
            lens.routes.query(key)
            {
                if  imports.contains($0.culture), 
                    lens.exists($0), 
                    disambiguator.matches($0, context: self.context)
                {
                    selection.append($0)
                }
            }
        }

        inspect(self.local)
        for lens:Tree.Pinned in self.context.foreign.values
        {
            inspect(lens)
        }

        return selection
    }
}
extension Resolver
{
    func resolve(expression:String, 
        imports:Set<Module>, 
        scope:LexicalScope?, 
        stems:Route.Stems) throws -> GlobalLink.Presentation
    {
        let schemeless:Substring 
        let scheme:Scheme 
        if  let colon:String.Index = expression.firstIndex(of: ":")
        {
            if expression[..<colon] == "doc" 
            {
                scheme = .doc 
            }
            else 
            {
                throw _SymbolLink.ResolutionError.init(expression, problem: .scheme)
            }
            schemeless = expression[expression.index(after: colon)...]
        }
        else 
        {
            scheme = .symbol
            schemeless = expression[...]
        }
        var slashes:Int = 0
        for index:String.Index in schemeless.indices 
        {
            if  slashes <  2, schemeless[index] == "/" 
            {
                slashes += 1
                continue 
            }
            do 
            {
                let uri:URI = try .init(relative: schemeless[index...])
                if  slashes > 1 
                {
                    var link:GlobalLink = .init(uri)
                    // uri begins with an authority component (package residency).
                    // '//swift-foo/foomodule/footype.foomember(_:)'.
                    guard   let residency:PackageIdentifier = 
                                link.descend().map(PackageIdentifier.init(_:)),
                            let residency:Tree.Pinned = self.linked[residency]
                    else 
                    {
                        throw _SymbolLink.ResolutionProblem.residency
                    }

                    // TODO: we do not support version/branch/tag components, 
                    // but if we did, this is where we would add it.
                    // ...

                    guard let link:_SymbolLink = try .init(link)
                    else 
                    {
                        return .package(residency.nationality)
                    }
                    // if there are additional path components after the package name, 
                    // then the package name is irrelevant, since all module namespaces 
                    // are already unique within a resolution context.
                    return try self.resolve(scheme: scheme, 
                        symbolLink: link, 
                        imports: imports, 
                        scope: nil, 
                        stems: stems)
                }
                else if let link:_SymbolLink = try .init(uri)
                {
                    let scope:LexicalScope? = slashes == 0 ? scope : nil
                    return try self.resolve(scheme: scheme, 
                        symbolLink: link, 
                        imports: imports, 
                        scope: scope, 
                        stems: stems)
                }
            }
            catch let error 
            {
                throw _SymbolLink.ResolutionError.init(expression, error)
            }
        }
        throw _SymbolLink.ResolutionError.init(expression, problem: .empty)
    }
    private 
    func resolve(scheme:Scheme, symbolLink link:_SymbolLink, 
        imports:Set<Module>, 
        scope:LexicalScope?, 
        stems:Route.Stems) throws -> GlobalLink.Presentation
    {
        if  case .doc = scheme, 
            let article:Article = self.resolve(docLink: link, 
                imports: imports, 
                scope: scope, 
                stems: stems)
        {
            return .article(article)
        }
        let link:_SymbolLink = link.disambiguated()
        let resolution:_SymbolLink.Resolution?
        if  let nationality:_SymbolLink.Nationality = link.nationality
        {
            guard let local:Tree.Pinned = self.linked[nationality.id]
            else 
            {
                throw _SymbolLink.ResolutionProblem.nationality
            }
            // we *could* support re-slicing a pinned package to a version that 
            // is an ancestor of the current (branch, revision) tuple. 
            // but currently, we do not.
            if  let version:VersionSelector = nationality.version, 
                let version:Version = local.tree.find(version), 
                    version != local.version
            {
                throw _SymbolLink.ResolutionProblem.nationalVersion
            }
            // filtering by import set is still useful, even with a nationality
            resolution = local.resolve(link.revealed, scope: scope, stems: stems)
            {
                imports.contains($0.culture) && 
                local.exists($0) && 
                link.disambiguator.matches($0, context: self.context)
            }
        }
        else 
        {
            resolution = self.resolve(symbolLink: link.revealed, 
                imports: imports, 
                scope: scope, 
                stems: stems)
        }
        return .init(try .init(resolution), visible: link.count)
    }
    private 
    func resolve(docLink link:_SymbolLink, 
        imports:Set<Module>, 
        scope:LexicalScope?, 
        stems:Route.Stems) -> Article?
    {
        if  let scope:LexicalScope, 
            let article:AtomicPosition<Article> = scope.scan(concatenating: link, 
                stems: stems, 
                until: { self.context[$0.namespace.nationality]?.articles.find(.init($0)) })
        {
            return article.atom
        }
        // can’t use a namespace as a key field if that namespace was not imported
        if  let path:_SymbolLink = link.suffix,
            let namespace:AtomicPosition<Module> = self.namespaces.linked[.init(link.first)], 
                imports.contains(namespace.atom), 
            let pinned:Tree.Pinned = self.context[namespace.nationality],
            let article:Route = stems[namespace.atom, straight: path], 
            let article:AtomicPosition<Article> = pinned.articles.find(.init(article))
        {
            return article.atom
        }
        else 
        {
            return nil
        }
    }
    private 
    func resolve(symbolLink link:_SymbolLink, 
        imports:Set<Module>, 
        scope:LexicalScope?, 
        stems:Route.Stems) -> _SymbolLink.Resolution?
    {
        if  let scope:LexicalScope, 
            let selection:Selection<Composite> = scope.scan(concatenating: link, 
                stems: stems, 
                until: 
                { 
                    self.select($0, disambiguator: link.disambiguator, imports: imports) 
                })
        {
            return .init(selection)
        }
        // can’t use a namespace as a key field if that namespace was not imported
        guard   let namespace:AtomicPosition<Module> = self.namespaces.linked[.init(link.first)], 
                    imports.contains(namespace.atom)
        else 
        {
            return nil
        }
        guard   let link:_SymbolLink = link.suffix 
        else 
        {
            return .module(namespace.atom)
        }
        if  let key:Route = stems[namespace.atom, link], 
            let selection:Selection<Composite> = self.select(key, 
                disambiguator: link.disambiguator, 
                imports: imports)
        {
            return .init(selection)
        }
        else 
        {
            return nil
        }
    }
}
