import DOM
import HTML
import Notebook
import SymbolAvailability
import SymbolGraphs
import SymbolSource
import Versions

extension SymbolPage 
{
    struct Breadcrumbs:RandomAccessCollection
    {
        let host:SymbolReference?
        let base:SymbolReference 
        private(set)
        var elements:[(display:String, uri:String)]

        var startIndex:Int 
        {
            -1
        }
        var endIndex:Int 
        {
            self.elements.endIndex
        }
        subscript(index:Int) -> HTML.Element<Never> 
        {
            if index == self.startIndex 
            {
                return .li(self.base.name)
            }
            else 
            {
                let element:(display:String, uri:String) = self.elements[index]
                return .li(.highlight(element.display, .type, uri: element.uri))
            }
        }
    }
}
extension SymbolPage.Breadcrumbs 
{
    init(base:SymbolReference, host:SymbolReference?, 
        context:__shared some PackageContext, 
        cache:inout ReferenceCache) throws 
    {
        self.base = base 
        self.host = host 
        self.elements = []
        self.elements.reserveCapacity(self.host == nil ? 
            base.path.count - 1 : 
            base.path.count)
        var next:SymbolReference? = try self.host ?? base.scope.map 
        {
            try cache.load($0.target, context: context)
        }
        while let current:SymbolReference = next 
        {
            self.elements.append((display: current.name, uri: current.uri))
            next = try current.scope.map 
            {
                try cache.load($0.target, context: context)
            }
        }
    }
}

extension SymbolPage 
{
    struct Names 
    {
        let breadcrumbs:Breadcrumbs
        let culture:
        (
            composite:ModuleReference, 
            base:ModuleReference?,
            host:ModuleReference?
        )
    }
}
extension SymbolPage.Names 
{
    init(_ symbol:AtomicPosition<Symbol>, base:SymbolReference, 
        context:__shared some AnisotropicContext, 
        cache:inout ReferenceCache) throws 
    {
        assert(context.local.nationality == symbol.nationality)

        self.culture.composite = try cache.load(symbol.culture, context: context)

        self.culture.base = nil
        self.culture.host = nil

        self.breadcrumbs = try .init(base: _move base, host: nil, 
            context: context, 
            cache: &cache)
    }
    init(_ compound:CompoundPosition, base:SymbolReference, 
        context:__shared some AnisotropicContext, 
        cache:inout ReferenceCache) throws 
    {
        assert(context.local.nationality == compound.nationality)

        self.culture.composite = try cache.load(compound.culture, context: context)
        let host:SymbolReference = try cache.load(compound.host, context: context)

        let compound:Compound = compound.atoms

        self.culture.base = compound.base.culture == compound.culture ? nil :
            try cache.load(compound.base.culture, context: context)
        self.culture.host = compound.host.culture == compound.culture ? nil :
            try cache.load(compound.host.culture, context: context)
        
        self.breadcrumbs = try .init(base: _move base, host: _move host, 
            context: context, 
            cache: &cache)
    }
}
struct SymbolPage 
{
    let branch:Tag
    let evolution:Evolution
    let navigator:Navigator
    let names:Names
    let conditions:Organizer.Conditional
    let notes:Organizer.Topics.Notes?
    let fragments:Notebook<Highlight, String>
    let availability:Availability
    let topics:Organizer.Topics

    let overview:[UInt8]?
    let discussion:[UInt8]?

    init(_ symbol:AtomicPosition<Symbol>, 
        documentation:__shared DocumentationExtension<Never>, 
        searchable:[String],
        evolution:Evolution,
        context:__shared BidirectionalContext, 
        cache:inout ReferenceCache) throws 
    {
        assert(context.local.nationality == symbol.nationality)

        guard   let declaration:Declaration<Symbol> = 
                    context.local.declaration(for: symbol.atom)
        else 
        {
            throw History.DataLoadingError.declaration
        }

        let base:SymbolReference = try cache.load(symbol, context: context)
        try self.init(documentation: documentation, 
            declaration: _move declaration, 
            searchable: _move searchable,
            evolution: _move evolution, 
            topics: try .init(for: symbol.atom, base: base, 
                context: context, 
                cache: &cache), 
            names: try .init(symbol, base: _move base, 
                context: context, 
                cache: &cache), 
            context: context, 
            cache: &cache)
    }
    init(_ compound:CompoundPosition, 
        documentation:__shared DocumentationExtension<Never>, 
        searchable:[String],
        evolution:Evolution,
        context:__shared some AnisotropicContext, 
        cache:inout ReferenceCache) throws 
    {
        assert(context.local.nationality == compound.nationality)

        guard   let declaration:Declaration<Symbol> = 
                    context[compound.base.nationality]?.declaration(for: compound.atoms.base)
        else 
        {
            throw History.DataLoadingError.declaration
        }
        
        let base:SymbolReference = try cache.load(compound.base, context: context)
        try self.init(documentation: documentation, 
            declaration: _move declaration,
            searchable: _move searchable,
            evolution: _move evolution, 
            topics: .init(notes: .feature(
                protocol: try .init(base, context: context, cache: &cache))), 
            names: try .init(compound, base: _move base, 
                context: context, 
                cache: &cache), 
            context: context, 
            cache: &cache)
    }
    init(documentation:__shared DocumentationExtension<Never>, 
        declaration:Declaration<Symbol>,
        searchable:[String],
        evolution:Evolution, 
        topics:Organizer.Topics, 
        names:Names,
        context:__shared some AnisotropicContext, 
        cache:inout ReferenceCache) throws 
    {
        self.branch = context.local.branch.id
        self.evolution = evolution
        self.navigator = .init(local: context.local, 
            searchable: _move searchable, 
            functions: cache.functions)
        self.conditions = try .init(declaration.extensionConstraints, 
            context: context, 
            cache: &cache)
        self.fragments = try declaration.fragments.map 
        {
            try cache.load($0, context: context).uri
        }
        self.availability = declaration.availability
        self.notes = topics.notes 

        self.overview = try cache.link(documentation.card, context: context)
        self.discussion = try cache.link(documentation.body, context: context)

        self.topics = topics
        self.names = names 
    }

    var breadcrumbs:Breadcrumbs 
    {
        self.names.breadcrumbs
    }
    var base:SymbolReference 
    {
        self.breadcrumbs.base 
    }
    var host:SymbolReference?
    {
        self.breadcrumbs.host
    }

    func render(element:PageElement) -> [UInt8]?
    {
        let html:HTML.Element<Never>?
        switch element
        {
        case .overview: 
            return self.overview ?? [UInt8].init("No overview available.".utf8)
        case .discussion: 
            return self.discussion
        case .topics: 
            html = self.topics.html

        case .title: 
            return [UInt8].init(self.navigator.title(self.base.name).utf8)
        case .constants: 
            return [UInt8].init(self.navigator.constants.utf8)
        
        case .availability: 
            html = self.availability.html
        case .base: 
            html = self.names.culture.base.map 
            { 
                .span($0.html, attributes: [.class("base")]) 
            }
        case .branch: 
            html = .span(self.branch.description)
        case .breadcrumbs: 
            html = .ol(self.breadcrumbs.reversed()) 
        
        case .consumers: 
            return nil 
        case .culture: 
            html = self.names.culture.composite.html 
        case .dependencies: 
            return nil
        case .fragments: 
            html = self.renderFragments()
        case .headline: 
            html = .h1(self.base.name)
        
        case .host: 
            html = self.names.culture.host.map 
            { 
                .span($0.html, attributes: [.class("namespace")]) 
            }
        case .kind: 
            return [UInt8].init(self.base.shape.title.utf8)
        case .meta: 
            return nil 

        case .notes: 
            html = self.renderNotes()
        case .notices: 
            html = self.evolution.newer?.html
        case .platforms: 
            html = self.availability.platforms.html
        case .station: 
            html = self.navigator.station
        case .versions: 
            html = self.evolution.items.html
        }
        return html?.node.rendered(as: [UInt8].self)
    }

    private 
    func renderFragments() -> HTML.Element<Never>
    {
        let fragments:[HTML.Element<Never>] = self.fragments.map 
        {
            .highlight($0.text, $0.color, uri: $0.link)
        }
        return .section(.pre(.code(fragments, attributes: [.class("swift")])), 
            attributes: [.class("declaration")])
    }
    private 
    func renderNotes() -> HTML.Element<Never>? 
    {
        var items:[HTML.Element<Never>] = []
        switch self.notes 
        {
        case nil: 
            break 
        
        case .feature(protocol: let coyote)?:
            items.append(.li(.p(.init(escaped: "Available because "),
                .code(.highlight(escaped: "Self", .type, uri: self.host?.uri),
                .init(escaped: " conforms to "),
                .code(.highlight(coyote.display.name, .type, uri: coyote.uri)),
                .init(escaped: "."))))) 
        
        case .member(overridden: let overridden)?: 
            for overridden:Organizer.Item<Organizer.Unconditional> in overridden
            {
                let prose:String 
                switch overridden.display.shape 
                {
                case .protocol: 
                    prose = "Implements requirement of "
                case _:
                    prose = "Overrides member of "
                }
                items.append(.li(.p(.init(escaped: prose), 
                    .code(.highlight(overridden.display.name, .type, uri: overridden.uri)), 
                    .init(escaped: "."))))
            }

        case .requirement(restated: let restated)?:
            items.append(.li(.p(escaped: "Required.", attributes: [.class("required")])))
            
            for restated:Organizer.Item<Organizer.Unconditional> in restated
            {
                items.append(.li(.p(.init(escaped: "Restates requirement of "),
                    .code(.highlight(restated.display.name, .type, uri: restated.uri)),
                    .init(escaped: "."))))
            }
        }
        
        let conditions:[HTML.Element<Never>] = self.conditions.htmls 
        if !conditions.isEmpty
        {
            let sentence:[HTML.Element<Never>] = 
                [.init(escaped: "Available when ")] + conditions + [.init(escaped: ".")]
            items.append(.li(.p(sentence)))
        }
        
        return items.isEmpty ? nil : .ul(items, attributes: [.class("notes")])
    }
}