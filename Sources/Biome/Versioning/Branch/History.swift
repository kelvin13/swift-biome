import Sediment
import SymbolGraphs

extension History
{
    enum MetadataLoadingError:Error 
    {
        case article
        case module
        case symbol
        case foreign
    }
    enum DataLoadingError:Error 
    {
        case topLevelArticles
        case topLevelSymbols
        case declaration
    }
}

extension History
{
    struct Metadata
    {
        var modules:Sediment<Version.Revision, Module.Metadata?>
        var articles:Sediment<Version.Revision, Article.Metadata?>
        var symbols:Sediment<Version.Revision, Symbol.Metadata?>
        var overlays:Sediment<Version.Revision, Overlay.Metadata?>

        init()
        {
            self.modules = .init()
            self.articles = .init()
            self.symbols = .init()
            self.overlays = .init()
        }
    }
    struct MetadataRollbacks
    {
        var modules:Sediment<Version.Revision, Module.Metadata?>.Rollbacks
        var articles:Sediment<Version.Revision, Article.Metadata?>.Rollbacks
        var symbols:Sediment<Version.Revision, Symbol.Metadata?>.Rollbacks
        var overlays:Sediment<Version.Revision, Overlay.Metadata?>.Rollbacks
    }
}
extension History.Metadata
{
    mutating
    func erode(until previous:Version.Revision) -> History.MetadataRollbacks
    {
        .init(modules: self.modules.erode(until: previous), 
            articles: self.articles.erode(until: previous), 
            symbols: self.symbols.erode(until: previous), 
            overlays: self.overlays.erode(until: previous))
    }
}

extension History
{
    struct Data
    {
        var topLevelArticles:Sediment<Version.Revision, Set<Article>>
        var topLevelSymbols:Sediment<Version.Revision, Set<Symbol>>
        var declarations:Sediment<Version.Revision, Declaration<Symbol>>

        var standaloneDocumentation:Sediment<Version.Revision, DocumentationExtension<Never>>
        var cascadingDocumentation:Sediment<Version.Revision, DocumentationExtension<Symbol>>

        init()
        {
            self.topLevelArticles = .init()
            self.topLevelSymbols = .init()
            self.declarations = .init()

            self.standaloneDocumentation = .init()
            self.cascadingDocumentation = .init()
        }
    }
    struct DataRollbacks
    {
        var topLevelArticles:Sediment<Version.Revision, Set<Article>>.Rollbacks
        var topLevelSymbols:Sediment<Version.Revision, Set<Symbol>>.Rollbacks
        var declarations:Sediment<Version.Revision, Declaration<Symbol>>.Rollbacks

        var standaloneDocumentation:Sediment<Version.Revision, DocumentationExtension<Never>>.Rollbacks
        var cascadingDocumentation:Sediment<Version.Revision, DocumentationExtension<Symbol>>.Rollbacks
    }
}
extension History.Data
{
    mutating
    func erode(until previous:Version.Revision) -> History.DataRollbacks
    {
        .init(topLevelArticles: self.topLevelArticles.erode(until: previous), 
            topLevelSymbols: self.topLevelSymbols.erode(until: previous), 
            declarations: self.declarations.erode(until: previous), 
            standaloneDocumentation: self.standaloneDocumentation.erode(until: previous),
            cascadingDocumentation: self.cascadingDocumentation.erode(until: previous))
    }
}

struct History
{
    var metadata:Metadata
    var data:Data

    init()
    {
        self.metadata = .init()
        self.data = .init()
    }
}
extension History
{
    struct Rollbacks
    {
        let metadata:MetadataRollbacks
        let data:DataRollbacks
    }

    mutating 
    func erode(until previous:Version.Revision) -> Rollbacks
    {
        .init(metadata: self.metadata.erode(until: previous), 
            data: self.data.erode(until: previous))
    }
}
