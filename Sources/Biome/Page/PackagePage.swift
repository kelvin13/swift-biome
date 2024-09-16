import DOM
import HTML 

struct PackagePage 
{
    struct Trade 
    {
        let partners:[(package:PackageReference, version:VersionSelector)]

        init(_ pinned:__shared some Sequence<Tree.Pinned>, 
            functions:__shared Service.PublicFunctionNames)
        {
            self.partners = pinned.map 
            {
                (.init($0, functions: functions), $0.selector ?? .tag($0.branch.id))
            }
        }

        var html:HTML.Element<Never>?
        {
            if self.partners.isEmpty 
            {
                return nil 
            }
            return .tbody(self.partners.map 
            {
                return .tr(
                    .td($0.package.name.string), 
                    .td(.a($0.version.description, attributes: [.href($0.package.uri)])))
            })
        }
    }

    let branch:Tag
    let evolution:Evolution 
    let navigator:Navigator 
    let dependencies:Trade
    let consumers:Trade
    private(set)
    var modules:[ModuleCard]
    let logo:[UInt8]

    init(logo:[UInt8], 
        searchable:[String], 
        evolution:Evolution, 
        context:__shared BidirectionalContext, 
        cache:inout ReferenceCache) throws
    {
        self.branch = context.local.branch.id
        self.evolution = evolution
        self.navigator = .init(local: context.local, 
            searchable: _move searchable, 
            functions: cache.functions)
        self.dependencies = .init(context.dependencies, 
            functions: cache.functions)
        self.consumers = .init(context.consumers.lazy.map(\.pinned), 
            functions: cache.functions)
        self.logo = logo 

        self.modules = []
        for period:Period<IntrinsicSlice<Module>> in context.local.modules
        {
            for module:Module.Intrinsic in period.axis where context.local.exists(module.culture)
            {
                let position:AtomicPosition<Module> = module.culture.positioned(period.branch)

                let module:ModuleReference = try cache.load(position, context: context)
                let overview:DOM.Flattened<GlobalLink.Presentation>? = 
                    context[position.nationality]?.documentation(for: position.atom)?.card
                self.modules.append(.init(reference: module, 
                    overview: try overview.flatMap { try cache.link($0, context: context) }))
            }
        }
        self.modules.sort(by: |<|)
    }

    func render(element:PageElement) -> [UInt8]?
    {
        let html:HTML.Element<Never>?
        switch element
        {
        case .overview: 
            return nil
        case .discussion: 
            return nil
        case .topics: 
            html = .div(.section(
                    .h2(escaped: "Modules"), 
                    .ul(self.modules.map(\.html), 
                attributes: [.class("topics members")])))
        
        case .title: 
            return [UInt8].init(self.navigator.title.utf8)
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
            html = self.consumers.html.map 
            {
                .table(.thead(.tr(.td(escaped: "Consumer"), .td(escaped: "Version"))), $0)
            }
        case .culture: 
            return nil
        case .dependencies: 
            html = self.dependencies.html.map 
            {
                .table(.thead(.tr(.td(escaped: "Dependency"), .td(escaped: "Version"))), $0)
            }
        case .fragments: 
            return nil
        case .headline: 
            html = .h1(self.navigator.title)
        case .host: 
            return nil 
        case .kind: 
            let kind:String 
            switch self.navigator.nationality.name
            {
            case .swift:        kind = "Standard Library"
            case .core:         kind = "Core Libraries"
            case .community:    kind = "Package"
            }
            return [UInt8].init(kind.utf8)
        
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

        //         let pie:SVG.Root<Never> = Pie.svg(
        //         [
        //             .init(weight: 57, classes: "-pink"),
        //             .init(weight: 27, classes: "-yellow"),
        //             .init(weight: 16, classes: "-white"),
        //         ])
        //         substitutions[.discussion] = .div(
        //             .div(.init(escaped: pie.rendered(as: [UInt8].self)), 
        //                 attributes: [.class("pie-color")]),
        //             .div(attributes: [.class("pie-geometry")]),
        //             attributes: [.class("pie")])
    }
}