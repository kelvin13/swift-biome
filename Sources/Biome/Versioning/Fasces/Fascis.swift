import SymbolGraphs

struct Fascis:Sendable 
{
    private
    let _articles:IntrinsicSlice<Article>, 
        _symbols:IntrinsicSlice<Symbol>,
        _modules:IntrinsicSlice<Module>,
        _overlays:OverlayTable
    private 
    let _routes:RoutingTable
    
    let history:History

    /// The last version contained within this fascis.
    let latest:Version
    /// The version this fascis (and its original branch) was forked from.
    let fork:Version?


    init(
        modules:IntrinsicSlice<Module>, 
        articles:IntrinsicSlice<Article>, 
        symbols:IntrinsicSlice<Symbol>,
        overlays:OverlayTable,
        history:History,
        routes:RoutingTable,
        branch:Version.Branch, 
        limit:Version.Revision, 
        fork:Version?)
    {
        self._articles = articles
        self._symbols = symbols
        self._modules = modules
        self._overlays = overlays

        self._routes = routes

        self.history = history 

        self.latest = .init(branch, limit)
        self.fork = nil
    }
    /// The index of the original branch this fascis was cut from.
    /// 
    /// This is the branch that contains the fascis, not the branch 
    /// the fascis was forked from.
    var branch:Version.Branch 
    {
        self.latest.branch
    }
    /// The index of the last revision contained within this fascis.
    var limit:Version.Revision 
    {
        self.latest.revision
    }

    var routes:Period<RoutingTable> 
    {
        .init(self._routes, latest: self.latest, fork: self.fork)
    }
}
extension Fascis
{
    var modules:Period<IntrinsicSlice<Module>>
    {
        .init(self._modules, latest: self.latest, fork: self.fork)
    }
    var articles:Period<IntrinsicSlice<Article>>
    {
        .init(self._articles, latest: self.latest, fork: self.fork)
    }
    var symbols:Period<IntrinsicSlice<Symbol>>
    {
        .init(self._symbols, latest: self.latest, fork: self.fork)
    }
    var overlays:Period<OverlayTable>
    {
        .init(self._overlays, latest: self.latest, fork: self.fork)
    }
}
extension Fascis
{
    struct Metadata
    {
        fileprivate 
        let base:Fascis
    }

    var metadata:Metadata
    {
        .init(base: self)
    }
}
extension Fascis.Metadata
{
    var modules:Period<IntrinsicSlice<Module>>.FieldView<Module.Metadata?>
    {
        .init(self.base.modules, sediment: self.base.history.metadata.modules)
    }
    var articles:Period<IntrinsicSlice<Article>>.FieldView<Article.Metadata?>
    {
        .init(self.base.articles, sediment: self.base.history.metadata.articles)
    }
    var symbols:Period<IntrinsicSlice<Symbol>>.FieldView<Symbol.Metadata?>
    {
        .init(self.base.symbols, sediment: self.base.history.metadata.symbols)
    }
    var overlays:Period<OverlayTable>.FieldView<Overlay.Metadata?>
    {
        .init(self.base.overlays, sediment: self.base.history.metadata.overlays)
    }
}

extension Fascis
{
    struct Data
    {
        fileprivate 
        let base:Fascis
    }

    var data:Data
    {
        .init(base: self)
    }
}

extension Fascis.Data
{
    var topLevelArticles:Period<IntrinsicSlice<Module>>.FieldView<Set<Article>>
    {
        .init(self.base.modules, sediment: self.base.history.data.topLevelArticles)
    }
    var topLevelSymbols:Period<IntrinsicSlice<Module>>.FieldView<Set<Symbol>>
    {
        .init(self.base.modules, sediment: self.base.history.data.topLevelSymbols)
    }
    var declarations:Period<IntrinsicSlice<Symbol>>.FieldView<Declaration<Symbol>>
    {
        .init(self.base.symbols, sediment: self.base.history.data.declarations)
    }
}
extension Fascis.Data
{
    var moduleDocumentation:Period<IntrinsicSlice<Module>>.FieldView<DocumentationExtension<Never>>
    {
        .init(self.base.modules, sediment: self.base.history.data.standaloneDocumentation)
    }
    var articleDocumentation:Period<IntrinsicSlice<Article>>.FieldView<DocumentationExtension<Never>>
    {
        .init(self.base.articles, sediment: self.base.history.data.standaloneDocumentation)
    }
    var symbolDocumentation:Period<IntrinsicSlice<Symbol>>.FieldView<DocumentationExtension<Symbol>>
    {
        .init(self.base.symbols, sediment: self.base.history.data.cascadingDocumentation)
    }
}