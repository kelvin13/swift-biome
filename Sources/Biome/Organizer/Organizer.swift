import DOM
import Notebook
import SymbolGraphs
import SymbolSource

struct Organizer
{
    var articles:[(ArticleCard, SortingKey)]
    var dependencies:[Package: Enclave<H3, Nationality, ModuleCard>]

    var requirements:[Shape: [(SymbolCard, SortingKey)]]

    var members:[Shape: [Module: Enclave<H4, Culture, (SymbolCard, SortingKey)>]]
    var removed:[Shape: [Module: Enclave<H4, Culture, (SymbolCard, SortingKey)>]]

    var implications:[Item<Unconditional>]

    var conformers:[Module: Enclave<H3, Culture, Item<Conditional>>]
    var conformances:[Module: Enclave<H3, Culture, Item<Conditional>>]

    var subclasses:[Module: Enclave<H3, Culture, Item<Unconditional>>]
    var refinements:[Module: Enclave<H3, Culture, Item<Unconditional>>]
    var implementations:[Module: Enclave<H3, Culture, Item<Unconditional>>]
    var restatements:[Module: Enclave<H3, Culture, Item<Unconditional>>]
    var overrides:[Module: Enclave<H3, Culture, Item<Unconditional>>]

    init() 
    {
        self.articles = []
        self.dependencies = [:]

        self.requirements = [:]

        self.members = [:]
        self.removed = [:]
        
        self.implications = []

        self.conformers = [:]
        self.conformances = [:]

        self.subclasses = [:]
        self.refinements = [:]
        self.implementations = [:]
        self.restatements = [:]
        self.overrides = [:]
    }
}

extension Organizer 
{
    mutating 
    func organize(dependencies:Set<Module>, 
        context:some AnisotropicContext, 
        cache:inout ReferenceCache) throws 
    {
        let groups:[Package: [Module]] = .init(grouping: dependencies, 
            by: \.nationality)
        for (nationality, atoms):(Package, [Module]) in groups
        {
            let nationality:Nationality = nationality == context.local.nationality ? 
                .local : .foreign(try cache.load(nationality, context: context))
            
            for atom:Module in atoms 
            {
                let module:ModuleReference = try cache.load(atom, context: context)
                let overview:DOM.Flattened<GlobalLink.Presentation>? = 
                    context[atom.nationality]?.documentation(for: atom)?.card
                let card:ModuleCard = .init(reference: module, 
                    overview: try overview.flatMap { try cache.link($0, context: context) })
                self.dependencies[atom.nationality, default: .init(nationality)]
                    .elements.append(card)
            }
        }
    }
    mutating 
    func organize(articles:Set<Article>, 
        context:some PackageContext, 
        cache:inout ReferenceCache) throws 
    {
        for atom:Article in articles
        {
            let article:ArticleReference = try cache.load(atom, context: context)
            let overview:DOM.Flattened<GlobalLink.Presentation>? = 
                context[atom.nationality]?.documentation(for: atom)?.card
            let card:ArticleCard = .init(headline: article.headline.formatted, 
                overview: try overview.flatMap { try cache.link($0, context: context) }, 
                uri: article.uri)
            self.articles.append((card, .atomic(article.path)))
        }
    }
    // The enclave may be different from the atom’s own culture.
    mutating 
    func organize(members:Set<Symbol>, enclave:Module, culture:Culture,
        context:some PackageContext, 
        cache:inout ReferenceCache) throws 
    {
        for member:Symbol in members
        {
            try self.add(member: member, to: enclave,
                    culture: culture, 
                    context: context, 
                    cache: &cache)
        }
    }
}
extension Organizer 
{
    mutating 
    func organize(_ traits:Branch.SymbolTraits, of host:SymbolReference, 
        diacritic:Diacritic, 
        culture:Culture,
        context:some PackageContext, 
        cache:inout ReferenceCache) throws
    {
        switch (host.shape, host.scope) 
        {
        case (_, .requirement(of: _)?):
            for parrot:Symbol in traits.downstream
            {
                self.restatements[diacritic.culture, default: .init(culture)]
                    .elements.append(try .init(parrot, context: context, cache: &cache))
            }
            for implementation:Symbol in traits.implementations
            {
                self.implementations[diacritic.culture, default: .init(culture)]
                    .elements.append(try .init(implementation, context: context, cache: &cache))
            }
        
        case (.protocol, _): 
            for (conformer, constraints):(Symbol, [Generic.Constraint<Symbol>]) in 
                traits.conformers
            {
                self.conformers[diacritic.culture, default: .init(culture)]
                    .elements.append(try .init(conformer, where: constraints, 
                        context: context, 
                        cache: &cache))
            }
            for refinement:Symbol in traits.downstream
            {
                self.refinements[diacritic.culture, default: .init(culture)]
                    .elements.append(try .init(refinement, context: context, cache: &cache))
            }

            try self.organize(members: traits.members, enclave: diacritic.culture, 
                culture: culture, 
                context: context, 
                cache: &cache)
        
        case (.concretetype(_), _): 
            for (conformance, constraints):(Symbol, [Generic.Constraint<Symbol>]) in 
                traits.conformances
            {
                self.conformances[diacritic.culture, default: .init(culture)]
                    .elements.append(try .init(conformance, where: constraints, 
                        context: context, 
                        cache: &cache))
            }
            for subclass:Symbol in traits.downstream
            {
                self.subclasses[diacritic.culture, default: .init(culture)]
                    .elements.append(try .init(subclass, context: context, cache: &cache))
            }
            for feature:Symbol in traits.features
            {
                try self.add(feature: feature, to: diacritic, 
                    culture: culture, 
                    context: context, 
                    cache: &cache)
            }

            try self.organize(members: traits.members, enclave: diacritic.culture,
                culture: culture, 
                context: context, 
                cache: &cache)

        case (.callable(_), _):
            for override:Symbol in traits.downstream
            {
                self.overrides[diacritic.culture, default: .init(culture)]
                    .elements.append(try .init(override, context: context, cache: &cache))
            }
        
        default: 
            break 
        }
    }
    private mutating 
    func add(member:Symbol, to enclave:Module, 
        culture:Culture,
        context:some PackageContext, 
        cache:inout ReferenceCache) throws
    {
        try self.add(composite: .init(atomic: member), to: enclave, 
            culture: culture, 
            context: context, 
            cache: &cache)
    }
    private mutating 
    func add(feature:Symbol, to diacritic:Diacritic, 
        culture:Culture,
        context:some PackageContext, 
        cache:inout ReferenceCache) throws
    {
        try self.add(composite: .init(feature, diacritic), to: diacritic.culture, 
            culture: culture, 
            context: context, 
            cache: &cache)
    }
    private mutating 
    func add(composite:Composite, to enclave:Module, 
        culture:Culture,
        context:some PackageContext,
        cache:inout ReferenceCache) throws 
    {
        guard   let declaration:Declaration<Symbol> = 
                    context[composite.base.nationality]?.declaration(for: composite.base)
        else 
        {
            throw History.DataLoadingError.declaration
        }

        let overview:DOM.Flattened<GlobalLink.Presentation>? = 
            context.documentation(for: composite.base)?.card 
        
        let composite:CompositeReference = try cache.load(composite, context: context)
        let card:SymbolCard = .init(signature: declaration.signature, 
            overview: try overview.flatMap { try cache.link($0, context: context) }, 
            uri: composite.uri)
        let shape:Shape = composite.base.shape
        if  declaration.availability.isUsable 
        {
            self.members[shape, default: [:]][enclave, default: .init(culture)]
                .elements.append((card, composite.key))
        }
        else 
        {
            self.removed[shape, default: [:]][enclave, default: .init(culture)]
                .elements.append((card, composite.key))
        }
    }
}

extension Organizer 
{
    mutating
    func organize(_ roles:Branch.SymbolRoles, 
        context:some AnisotropicContext, 
        cache:inout ReferenceCache) throws
    {
        for role:Symbol in roles 
        {
            try self.add(role: role, context: context, cache: &cache)
        }
    }
    private mutating 
    func add(role:Symbol, context:some AnisotropicContext, cache:inout ReferenceCache) 
        throws
    {
        // protocol roles may originate from a different package
        let symbol:SymbolReference = try cache.load(role, context: context)
        switch symbol.shape
        {
        case .protocol:
            self.implications.append(try .init(symbol, context: context, cache: &cache))
        case let shape:
            // this is always valid, because non-protocol roles are always 
            // requirements, and requirements always live in the same package as 
            // the protocol they are part of.
            guard   let declaration:Declaration<Symbol> = 
                        context.local.declaration(for: role)
            else 
            {
                throw History.DataLoadingError.declaration
            }
            let overview:DOM.Flattened<GlobalLink.Presentation>? = 
                context.documentation(for: role)?.card
            let card:SymbolCard = .init(signature: declaration.signature, 
                overview: try overview.flatMap { try cache.link($0, context: context) }, 
                uri: symbol.uri)
            self.requirements[shape, default: []].append((card, .atomic(symbol.path)))
        }
    }
}
