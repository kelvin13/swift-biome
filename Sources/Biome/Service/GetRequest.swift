import URI 

struct GetRequest 
{
    enum Query 
    {
        case redirect(canonical:URI?)
        case documentation(DocumentationQuery)
        case selection(DisambiguationQuery)
        case migration(DisambiguationQuery)
    }

    let uri:URI
    var query:Query

    private
    init(_ request:URI, uri:URI, query:Query)
    {
        if uri ~= request 
        {
            self.query = query
        }
        else 
        {
            if case .documentation(let query) = query 
            {
                self.query = .redirect(canonical: query.canonical) 
            }
            else 
            {
                self.query = .redirect(canonical: nil) 
            }
        }
        self.uri = uri 
    }
}
extension GetRequest 
{
    init(_ request:URI, residency pinned:__shared Tree.Pinned, 
        functions:__shared Service.PublicFunctionNames)
    {
        let address:Address = .init(residency: pinned)
        self.init(request, uri: address.uri(functions: functions), 
            query: .documentation(.init(.package(pinned.nationality), 
                _objects: .init(),
                pinned: pinned)))
    }

    init?(_ request:URI, residency pinned:Tree.Pinned, 
        namespace:AtomicPosition<Module>,
        functions:__shared Service.PublicFunctionNames)
    {
        guard   let pinned:Tree.Pinned = 
                    pinned.excavate(namespace.atom).map(pinned.repinned(to:))
        else 
        {
            return nil 
        }
        let address:Address = .init(residency: pinned, 
            namespace: pinned.tree[local: namespace])
        self.init(request, uri: address.uri(functions: functions), 
            query: .documentation(.init(.module(namespace), 
                _objects: pinned.documentation(for: namespace.atom) ?? .init(), 
                pinned: pinned)))
    }

    init?(_ request:URI, residency pinned:Tree.Pinned,
        namespace:AtomicPosition<Module>, 
        article:AtomicPosition<Article>, 
        functions:__shared Service.PublicFunctionNames)
    {
        guard   let pinned:Tree.Pinned = 
                    pinned.excavate(article.atom).map(pinned.repinned(to:))
        else 
        {
            return nil 
        }
        let address:Address = .init(residency: pinned, 
            namespace: pinned.tree[local: namespace],
            article: pinned.tree[local: article])
        self.init(request, uri: address.uri(functions: functions), 
            query: .documentation(.init(.article(article), 
                _objects: pinned.documentation(for: article.atom) ?? .init(), 
                pinned: pinned)))
    }
}
extension GetRequest 
{
    init?(_ request:URI, extant composite:Composite, context:__shared DirectionalContext, 
        functions:__shared Service.PublicFunctionNames)
    {
        var origin:Symbol = composite.base 
        let documentation:DocumentationExtension<Never>? = context.documentation(for: &origin)
        var canonical:URI? = origin == composite.base || (documentation?.isEmpty ?? true) ? 
            nil : context.address(of: origin)?.uri(functions: functions) 
        let target:DocumentationQuery.Target 
        let uri:URI 
        if let compound:Compound = composite.compound 
        {
            guard   let base:Tree.Pinned = context[compound.base.nationality],
                    let host:Tree.Pinned = context[compound.host.nationality],
                    let compound:CompoundPosition = 
                        compound.positioned(bisecting: context.local.modules, 
                            host: host.symbols, 
                            base: base.symbols),
                    let address:Address = context.local.address(of: compound.atoms, 
                        host: host.tree[local: compound.host], 
                        base: base.tree[local: compound.base], 
                        context: context)
            else 
            {
                return nil 
            }

            canonical = canonical ?? context.local.address(of: compound.base.atom, 
                symbol: base.tree[local: compound.base], 
                context: context)?.uri(functions: functions)
            target = .compound(compound)
            uri = address.uri(functions: functions)
        }
        else 
        {
            guard   let symbol:AtomicPosition<Symbol> = 
                        composite.base.positioned(bisecting: context.local.symbols), 
                    let address:Address = context.local.address(of: symbol.atom, 
                        symbol: context.local.tree[local: symbol], 
                        context: context)
            else 
            {
                return nil 
            }

            target = .symbol(symbol)
            uri = address.uri(functions: functions)
        }
        
        self.init(request, uri: uri, query: .documentation(.init(target, 
            canonical: canonical,
            _objects: documentation ?? .init(), 
            pinned: context.local)))
    }

    init?(_ request:URI, choices:[Composite], context:__shared DirectionalContext, 
        functions:__shared Service.PublicFunctionNames, 
        migration:Bool = false)
    {
        guard   let exemplar:Composite = choices.first, 
                let address:Address = context.local.address(of: exemplar, disambiguate: .never, 
                    context: context)
        else 
        {
            return nil 
        }
        let query:DisambiguationQuery = .init(nationality: context.local.nationality,
            version: context.local.version, 
            choices: .init(grouping: choices, by: \.culture))
        self.init(request, uri: address.uri(functions: functions) , 
            query: migration ? .migration(query) : .selection(query))
    }
}

struct DocumentationQuery
{
    typealias _Objects = DocumentationExtension<Never> 

    enum Target 
    {
        case package(Package)
        case module(AtomicPosition<Module>)
        case article(AtomicPosition<Article>)
        case symbol(AtomicPosition<Symbol>)
        case compound(CompoundPosition)
    }

    let target:Target 
    let canonical:URI?
    let _objects:_Objects
    let version:Version 
    let token:UInt 

    // var nationality:Package 
    // {
    //     switch self.target 
    //     {
    //     case .package(let nationality): 
    //         return nationality 
    //     case .module(let module): 
    //         return module.nationality 
    //     case .article(let article): 
    //         return article.nationality 
    //     case .composite(let composite): 
    //         return composite.nationality 
    //     }
    // }

    init(_ target:Target, 
        canonical:URI? = nil,
        _objects:_Objects, 
        pinned:__shared Tree.Pinned)
    {
        self.target = target 
        self.canonical = canonical
        self.version = pinned.version 
        self._objects = _objects
        self.token = pinned.revision.token
    }
}
struct DisambiguationQuery
{
    let nationality:Package
    let version:Version 
    let choices:[Module: [Composite]]
}
// struct MigrationQuery 
// {
//     let nationality:Package
//     /// The requested version. None of the symbols in this query 
//     /// exist in this version.
//     let requested:Version
//     /// The list of potentially matching composites.
//     /// 
//     /// It is not possible to efficiently look up the most 
//     /// recent version a compound appears in. Therefore, when 
//     /// generating a URL for a compound choice, we should maximally 
//     /// disambiguate it, and allow HTTP redirection to resolve it 
//     /// to an appropriate version, should a user click on that URL.
//     let choices:[Composite]
// }
