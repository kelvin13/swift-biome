import HTML 

struct ModulePage 
{
    let branch:Tag
    let evolution:Evolution

    let navigator:Navigator
    let culture:ModuleReference
    let topics:Organizer.Topics

    let overview:[UInt8]?
    let discussion:[UInt8]?
    let logo:[UInt8]

    init(_ module:AtomicPosition<Module>, logo:[UInt8],
        documentation:__shared DocumentationExtension<Never>,
        searchable:[String],
        evolution:Evolution,
        context:__shared some AnisotropicContext, 
        cache:inout ReferenceCache) throws 
    {
        assert(context.local.nationality == module.nationality)

        self.branch = context.local.branch.id
        self.evolution = evolution 
        self.navigator = .init(local: context.local, 
            searchable: _move searchable, 
            functions: cache.functions)
        self.culture = try cache.load(module, context: context)

        self.overview = try cache.link(documentation.card, context: context)
        self.discussion = try cache.link(documentation.body, context: context)

        self.topics = try .init(for: module.atom, 
            context: context, 
            cache: &cache)
        self.logo = logo
    }

    func render(element:PageElement) -> [UInt8]?
    {
        let html:HTML.Element<Never>?
        switch element
        {
        case .overview: 
            return self.overview
        case .discussion: 
            return self.discussion
        case .topics: 
            html = self.topics.html
        case .title: 
            return [UInt8].init(self.navigator.title(self.culture.name.string).utf8)
        case .constants: 
            return [UInt8].init(self.navigator.constants.utf8)
        case .availability: 
            return nil 
        case .base: 
            return nil
        case .branch: 
            html = .span(self.branch.description) 
        case .breadcrumbs: 
            return self.logo
        case .consumers: 
            return nil 
        case .culture: 
            html = self.navigator.nationality.html 
        case .dependencies: 
            return nil
        case .fragments: 
            return nil
        case .headline: 
            html = .h1(self.culture.name.string)
        case .host: 
            return nil 
        case .kind: 
            return [UInt8].init("Module".utf8)
        case .meta: 
            return nil
        case .notes: 
            return nil
        case .notices: 
            html = self.evolution.newer?.html
        case .platforms: 
            return nil
        case .station: 
            html = self.navigator.station
        case .versions: 
            html = self.evolution.items.html
        }
        return html?.node.rendered(as: [UInt8].self)
    }
}