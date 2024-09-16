import HTML 
import MIME
import SymbolSource

extension PackageIdentifier 
{
    var station:String 
    {
        switch self
        {
        case .swift, .core:
            return "swift"
        case .community(normalized: let name):
            return name 
        }
    }
}

@frozen public 
enum PageElement:Hashable, Sendable
{
    case title 
    case constants 
    
    case availability 
    case base
    case branch
    case breadcrumbs
    case consumers
    case culture 
    case dependencies 
    case discussion
    case fragments
    case headline
    case host 
    case kind
    case meta
    case notes 
    case notices
    case platforms
    case overview
    case station 
    case topics
    case versions
} 

extension HTML.Root<PageElement> 
{
    static 
    var defaultPageTemplate:Self 
    {
        .init(
            .head(
                .title(.init(anchor: .title)),
                
                .meta(attributes: [.charset("UTF-8")]),
                .meta(attributes: [.name("viewport"), .content("width=device-width, initial-scale=1")]),
                
                .init(anchor: .meta),

                .script(.init(anchor: .constants)),
                .script(attributes: [.src("/search.js"), .defer]),
                .link(attributes: [.href("/biome.css"), .rel("stylesheet")]),
                .link(attributes: [.href("/favicon.png"), .rel("icon")]),
                .link(attributes: [.href("/favicon.ico"), .rel("icon"), .type(MIME.icon.rawValue)])),
            .body(
                .header(
                    .nav(.init(anchor: .breadcrumbs), attributes: [.class("breadcrumbs")]),
                    .div(
                        .div(
                            .form(.input(
                                    attributes: 
                                    [
                                        .id("search-input"),
                                        .type("search"),
                                        .placeholder("search symbols"),
                                        .autocomplete("off"),
                                    ]), 
                                attributes: 
                                [
                                    .role("search"), 
                                    .id("search"),
                                ]),
                            .input(attributes: 
                                [
                                    .id("version-menu-toggle"),
                                    .type("checkbox"),
                                    .autocomplete("off")
                                ]),
                            .label(.init(anchor: .station), .init(anchor: .branch), 
                                attributes: 
                                [
                                    .id("version"), 
                                    .for("version-menu-toggle"),
                                ]), 
                            attributes: [.class("toolbar")]),
                        .ol(attributes: [.id("search-results")]),
                        .div(.init(anchor: .versions), attributes: [.id("version-menu")]),
                        attributes: [.class("toolbar-container")])),
                .main(
                    .div(
                        .div([
                            .article(
                                .section(
                                    .div(
                                        .span(.init(anchor: .kind), attributes: [.class("kind")]),
                                        .span(
                                            .init(anchor: .host),
                                            .init(anchor: .culture),
                                            .init(anchor: .base), 
                                            attributes: [.class("nationality")]),
                                        attributes: [.class("eyebrows")]),
                                    
                                    .init(anchor: .headline),
                                    .init(anchor: .notices),
                                    .init(anchor: .overview),
                                    .init(anchor: .notes),
                                    .init(anchor: .availability), 
                                    attributes: [.class("introduction")]),
                                .init(anchor: .platforms),
                                .init(anchor: .fragments),
                                .init(anchor: .dependencies),
                                .init(anchor: .consumers),
                                .init(anchor: .discussion),
                                attributes: [.class("upper-container-left")])],
                            attributes: [.class("upper-container")]),
                        attributes: [.class("upper")]),
                    .div(.init(anchor: .topics), attributes: [.class("lower")]))), 
            attributes: [.lang("en")])
    }
}