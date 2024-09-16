import HTML 
import DOM

struct ArticlePage 
{
    let branch:Tag
    let evolution:Evolution
    let navigator:Navigator
    let culture:ModuleReference

    let metadata:Article.Metadata
    let discussion:[UInt8]?
    let logo:[UInt8]

    init(_ article:AtomicPosition<Article>, logo:[UInt8],
        documentation:__shared DocumentationExtension<Never>, 
        searchable:[String],
        evolution:Evolution,
        context:__shared some AnisotropicContext, 
        cache:inout ReferenceCache) throws 
    {
        assert(context.local.nationality == article.nationality)

        guard let metadata:Article.Metadata = context.local.metadata(local: article.atom) 
        else 
        {
            throw History.MetadataLoadingError.article
        }

        self.branch = context.local.branch.id
        self.evolution = evolution
        self.navigator = .init(local: context.local, 
            searchable: _move searchable, 
            functions: cache.functions)
        self.culture = try cache.load(article.culture, context: context)

        self.metadata = metadata
        self.logo = logo

        switch 
        (
            try cache.link(documentation.card, context: context),
            try cache.link(documentation.body, context: context)
        )
        {
        case (nil, nil):
            self.discussion = nil
        case (let head?, nil):
            self.discussion = head
        case (let head?, let body?):
            self.discussion = head + body
        case (nil, let body?):
            self.discussion = body
        }
    }

    func render(element:PageElement) -> [UInt8]?
    {
        let html:HTML.Element<Never>?
        switch element
        {
        case .overview: 
            return nil
        case .discussion: 
            return self.discussion
        case .topics: 
            return nil
        case .title: 
            return [UInt8].init(self.navigator.title(self.metadata.headline.plain).utf8)
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
            html = self.culture.html 
        case .dependencies: 
            return nil
        case .fragments: 
            return nil
        case .headline: 
            html = .h1(self.metadata.headline.formatted)
        case .host: 
            return nil 
        case .kind: 
            return [UInt8].init("Article".utf8)
        
        case .meta: 
            html = self.metadata.excerpt.isEmpty ? nil : .meta(attributes: 
            [
                .name("description"), 
                .content(DOM.escape(self.metadata.excerpt)),
            ])
        
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