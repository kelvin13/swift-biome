import DOM
import HTML 
import SymbolGraphs
import URI

struct DisambiguationPage 
{
    let navigator:Navigator
    private(set)
    var expression:String
    private(set)
    var choices:[Organizer.Enclave<Organizer.H4, Organizer.Culture, SymbolCard>]
    let logo:[UInt8]

    init(_ choices:[Module: [Composite]], logo:[UInt8], uri:URI,
        searchable:[String],
        context:__shared some AnisotropicContext, 
        cache:inout ReferenceCache) throws 
    {
        self.navigator = .init(local: context.local, 
            searchable: _move searchable, 
            functions: cache.functions)
        // does not use percent-encoding
        self.expression = ""
        // trim the root
        for vector:URI.Vector? in uri.path.dropFirst()
        {
            if case .push(let component)? = vector
            {
                self.expression += "/\(component)"
            }
        }
        self.choices = try choices.map 
        {
            assert($0.key.nationality == context.local.nationality)

            let id:Organizer.Culture = .accepted(try cache.load($0.key, context: context))
            let cards:[(SymbolCard, Organizer.SortingKey)] = try $0.value.map 
            {
                guard   let base:Tree.Pinned = context[$0.base.nationality],
                        let declaration:Declaration<Symbol> = 
                            base.declaration(for: $0.base)
                else 
                {
                    throw History.DataLoadingError.declaration
                }
                let overview:DOM.Flattened<GlobalLink.Presentation>? = 
                    base.documentation(for: $0.base)?.card 
                let composite:CompositeReference = try cache.load($0, context: context)
                let card:SymbolCard = .init(signature: declaration.signature, 
                    overview: try overview.flatMap { try cache.link($0, context: context) }, 
                    uri: composite.uri)
                return (card, composite.key)
            }
            return .init(id, elements: cards.sorted())
        }
        self.logo = logo
    }

    func render(element:PageElement) -> [UInt8]?
    {
        let html:HTML.Element<Never>?
        switch element
        {
        case .overview: 
            html = .p(escaped: "This link could refer to multiple symbols.")
        case .discussion: 
            return nil
        case .topics: 
            html = .div(.section(self.choices.lazy.map(\.htmls).joined(), 
                attributes: [.class("topics choices")]))
        case .title: 
            return [UInt8].init("Disambiguation Page".utf8)
        case .constants: 
            return [UInt8].init(self.navigator.constants.utf8)
        case .availability: 
            return nil 
        case .base: 
            return nil
        case .branch: 
            return nil
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
            html = .h1(self.expression)
        case .host: 
            return nil 
        case .kind: 
            return [UInt8].init("Disambiguation Page".utf8)
        case .meta: 
            return nil
        case .notes: 
            return nil
        case .notices: 
            return nil
        case .platforms: 
            return nil
        case .station: 
            html = self.navigator.station
        case .versions: 
            return nil
        }
        return html?.node.rendered(as: [UInt8].self)
    }
}