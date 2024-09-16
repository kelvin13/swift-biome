import DOM
import HTML
import Notebook
import SymbolSource

infix operator |<| :ComparisonPrecedence 

/// Orders two paths first by final component, and then by scope.
func |<| (
    lhs:(prefix:some Sequence<String>, last:String), 
    rhs:(prefix:some Sequence<String>, last:String)) -> Bool 
{
    if      lhs.last <  rhs.last 
    {
        return true 
    }
    else if lhs.last == rhs.last 
    {
        return lhs.prefix.lexicographicallyPrecedes(rhs.prefix)
    }
    else 
    {
        return false 
    }
}

extension Path 
{
    static 
    func |<| (lhs:Self, rhs:Self) -> Bool 
    {
        (lhs.prefix, lhs.last) |<| (rhs.prefix, rhs.last)
    }
}

extension Organizer 
{
    struct Topics 
    {
        enum Notes 
        {
            case feature(protocol:Item<Unconditional>)
            case member(overridden:[Item<Unconditional>])
            case requirement(restated:[Item<Unconditional>])

            func sorted() -> Self 
            {
                switch self 
                {
                case .feature(protocol: let coyote): 
                    return .feature(protocol: coyote)
                case .member(overridden: let overridden): 
                    return .member(overridden: overridden.sorted(by: |<|))
                case .requirement(restated: let restated): 
                    return .requirement(restated: restated.sorted(by: |<|))
                }
            }
        }

        let notes:Notes? 
        
        let articles:[ArticleCard]
        let dependencies:[Enclave<H3, Nationality, ModuleCard>]

        let requirements:[(Shape, [SymbolCard])]

        let members:[(Shape, [Enclave<H4, Culture, SymbolCard>])]
        let removed:[(Shape, [Enclave<H4, Culture, SymbolCard>])]

        let implications:[Item<Unconditional>]

        let conformers:[Enclave<H3, Culture, Item<Conditional>>]
        let conformances:[Enclave<H3, Culture, Item<Conditional>>]

        let subclasses:[Enclave<H3, Culture, Item<Unconditional>>]
        let refinements:[Enclave<H3, Culture, Item<Unconditional>>]
        let implementations:[Enclave<H3, Culture, Item<Unconditional>>]
        let restatements:[Enclave<H3, Culture, Item<Unconditional>>]
        let overrides:[Enclave<H3, Culture, Item<Unconditional>>]

        init(notes:Notes? = nil) 
        {
            self.notes = notes?.sorted()

            self.articles = []
            self.dependencies = []

            self.requirements = []

            self.members = []
            self.removed = []

            self.implications = []

            self.conformers = []
            self.conformances = []

            self.subclasses = []
            self.refinements = []
            self.implementations = []
            self.restatements = []
            self.overrides = []
        }
        private 
        init(_ organizer:Organizer, notes:Notes? = nil)
        {
            self.notes = notes?.sorted()
            
            self.articles = organizer.articles.sorted()
            self.dependencies = organizer.dependencies.values.sorted().map { $0.sorted(by: |<|) }

            self.requirements = organizer.requirements.sublists { $0.sorted() }

            self.members = organizer.members.sublists { $0.values.sorted().map { $0.sorted() } }
            self.removed = organizer.removed.sublists { $0.values.sorted().map { $0.sorted() } }

            self.implications = organizer.implications.sorted(by: |<|)

            self.conformers = organizer.conformers.values.sorted().map { $0.sorted(by: |<|) }
            self.conformances = organizer.conformances.values.sorted().map { $0.sorted(by: |<|) }

            self.subclasses = organizer.subclasses.values.sorted().map { $0.sorted(by: |<|) }
            self.refinements = organizer.refinements.values.sorted().map { $0.sorted(by: |<|) }
            self.implementations = organizer.implementations.values.sorted().map { $0.sorted(by: |<|) }
            self.restatements = organizer.restatements.values.sorted().map { $0.sorted(by: |<|) }
            self.overrides = organizer.overrides.values.sorted().map { $0.sorted(by: |<|) }
        }
    }
}
extension Dictionary where Key == Shape 
{
    fileprivate
    func sublists<Sublist>(_ transform:(Value) throws -> Sublist) rethrows -> [(Key, Sublist)]
    {
        try Key.allCases.compactMap
        {
            (key:Key) in try self[key].map { (key, try transform($0)) }
        }
    }
}

extension Organizer.Topics 
{
    init(for module:Module, 
        context:__shared some AnisotropicContext,
        cache:inout ReferenceCache) throws
    {
        guard let metadata:Module.Metadata = context.local.metadata(local: module)
        else 
        {
            throw History.MetadataLoadingError.module
        }
        guard let articles:Set<Article> = context.local.topLevelArticles(of: module) 
        else 
        {
            throw History.DataLoadingError.topLevelArticles
        }
        guard let symbols:Set<Symbol> = context.local.topLevelSymbols(of: module)
        else 
        {
            throw History.DataLoadingError.topLevelSymbols
        }

        var organizer:Organizer = .init()
        try organizer.organize(dependencies: metadata.dependencies, 
            context: context, 
            cache: &cache)
        try organizer.organize(articles: articles, 
            context: context, 
            cache: &cache)
        try organizer.organize(members: symbols, enclave: module, 
            culture: .primary, 
            context: context, 
            cache: &cache)
        self.init(_move organizer)
    }
    
    init(for atomic:Symbol, 
        base:__shared SymbolReference,
        context:__shared BidirectionalContext,
        cache:inout ReferenceCache) throws
    {
        guard let metadata:Symbol.Metadata = context.local.metadata(local: atomic)
        else 
        {
            throw History.MetadataLoadingError.symbol
        }

        var organizer:Organizer = .init()
        try organizer.organize(metadata.primary, of: base, 
            diacritic: .init(atomic: atomic),
            culture: .primary,
            context: context,
            cache: &cache)
        
        for (culture, accepted):(Module, Branch.SymbolTraits) in metadata.accepted 
        {
            try organizer.organize(accepted, of: base, 
                diacritic: .init(host: atomic, culture: culture), 
                culture: .accepted(try cache.load(culture, context: context)),
                context: context,
                cache: &cache)
        }
        for consumer:BidirectionalContext.Consumer in context.consumers
        {
            for culture:Module in consumer.modules 
            {
                assert(culture.nationality == consumer.nationality)

                let diacritic:Diacritic = .init(host: atomic, culture: culture)
                if  let extra:Overlay.Metadata = 
                        consumer.pinned.metadata(foreign: diacritic)
                {
                    try organizer.organize(extra.traits, of: base, 
                        diacritic: diacritic, 
                        culture: .nonaccepted(
                            try cache.load(culture, context: context), 
                            try cache.load(consumer.nationality, context: context)),
                        context: context,
                        cache: &cache)
                }
            }
        }
        let notes:Notes? 
        if let roles:Branch.SymbolRoles = metadata.roles 
        {
            switch (base.shape, base.scope) 
            {
            case (.protocol, _):
                try organizer.organize(roles, context: context, cache: &cache)
                notes = nil
            
            case (.callable,    .member?): 
                notes = .member(overridden: try roles.map 
                { 
                    try .init($0, context: context, cache: &cache) 
                })
            case (_,            .member?): 
                notes = nil
            case (_,            .requirement?):
                notes = .requirement(restated: try roles.map 
                { 
                    try .init($0, context: context, cache: &cache) 
                })
            case (_,            nil): 
                notes = nil 
            }
        }
        else 
        {
            notes = nil 
        }

        self.init(_move organizer, notes: _move notes)
    }
}


extension Organizer.Topics  
{
    var html:HTML.Element<Never>?
    {
        var sections:[HTML.Element<Never>] = []
        
        if !self.articles.isEmpty 
        {
            sections.append(.section(.ul(self.articles.map(\.html)),
                attributes: [.class("feed")]))
        }

        if !self.dependencies.isEmpty
        {
            sections.append(.section(self.dependencies.grid(heading: .h2("Dependencies")),
                attributes: [.class("topics dependencies")]))
        }
        
        if  let section:HTML.Element<Never> = self.refinements.section(
                h2: "Refinements",
                attributes: [.class("related")])
        {
            sections.append(section)
        }
        if  let section:HTML.Element<Never> = self.implementations.section(
                h2: "Implemented By",
                attributes: [.class("related")])
        {
            sections.append(section)
        }
        if  let section:HTML.Element<Never> = self.restatements.section(
                h2: "Restated By", 
                attributes: [.class("related")])
        {
            sections.append(section)
        }
        if  let section:HTML.Element<Never> = self.overrides.section(
                h2: "Overridden By", 
                attributes: [.class("related")])
        {
            sections.append(section)
        }
        
        if !self.requirements.isEmpty
        {
            sections.append(.section([.h2("Requirements")] + self.requirements.map 
                {
                    .section(.h3($0.0.plural), .ul($0.1.map(\.html)))
                },
                attributes: [.class("topics requirements")]))
        }
        if !self.members.isEmpty
        {
            sections.append(.section([.h2("Members")] + self.members.map 
                {
                    $0.1.grid(heading: .h3($0.0.plural))
                },
                attributes: [.class("topics members")]))
        }
        
        if  let section:HTML.Element<Never> = self.conformers.section(
                h2: "Conforming Types", 
                attributes: [.class("related")])
        {
            sections.append(section)
        }
        if  let section:HTML.Element<Never> = self.conformances.section(
                h2: "Conforms To", 
                attributes: [.class("related")])
        {
            sections.append(section)
        }
        if  let section:HTML.Element<Never> = self.subclasses.section(
                h2: "Subclasses", 
                attributes: [.class("related")])
        {
            sections.append(section)
        }
        if !self.implications.isEmpty
        {
            sections.append(.section(.h2("Implies"), .ul(self.implications.map(\.html)), 
                attributes: [.class("related")]))
        }

        if !self.removed.isEmpty
        {
            sections.append(.section([.h2("Removed Members")] + self.removed.map 
                {
                    $0.1.grid(heading: .h3($0.0.plural))
                },
                attributes: [.class("topics removed")]))
        }
        
        return sections.isEmpty ? nil : .div(sections)
    }
}


extension Collection where Element:HTMLConvertible
{
    fileprivate 
    func section(h2:String, attributes:[HTML.Element<Never>.Attribute] = []) 
        -> HTML.Element<Never>?
    {
        self.isEmpty ? nil : 
            .section([.h2(escaped: h2)] + self.lazy.flatMap(\.htmls), attributes: attributes)
    }
}
extension Sequence where Element:HTMLConvertible
{
    fileprivate 
    func grid(heading:HTML.Element<Never>) -> HTML.Element<Never>
    {
        var iterator:Iterator = self.makeIterator() 
        guard let first:Element.RenderedHTML = iterator.next()?.htmls
        else 
        {
            return .section(heading) 
        }
        // CSS grid will be unhappy if the first enclave has more than 1 dom element 
        var elements:[HTML.Element<Never>] = []
        if  first.count > 1 
        {
            elements.reserveCapacity(2 * self.underestimatedCount + 2)
            elements.append(heading)
            elements.append(.ul())
        }
        else 
        {
            elements.reserveCapacity(2 * self.underestimatedCount)
            elements.append(heading)
        }

        elements.append(contentsOf: _move first)

        while let next:Element.RenderedHTML = iterator.next()?.htmls
        {
            elements.append(contentsOf: next)
        }
        
        return .section(elements) 
    }
}
