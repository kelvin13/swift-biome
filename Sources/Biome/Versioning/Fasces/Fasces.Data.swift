import SymbolGraphs

extension Fasces
{
    struct Data
    {
        let base:Fasces
    }
    var data:Data
    {
        .init(base: self)
    }
}
extension Fasces.Data
{
    struct TopLevelArticles:FascesView
    {
        let base:Fasces
    }
    struct TopLevelSymbols:FascesView
    {
        let base:Fasces
    }
    struct Declarations:FascesView
    {
        let base:Fasces
    }

    struct ModuleDocumentation:FascesView
    {
        let base:Fasces
    }
    struct ArticleDocumentation:FascesView
    {
        let base:Fasces
    }
    struct SymbolDocumentation:FascesView
    {
        let base:Fasces
    }

    var topLevelArticles:TopLevelArticles
    {
        .init(base: self.base)
    }
    var topLevelSymbols:TopLevelSymbols
    {
        .init(base: self.base)
    }
    var declarations:Declarations
    {
        .init(base: self.base)
    }

    var moduleDocumentation:ModuleDocumentation
    {
        .init(base: self.base)
    }
    var articleDocumentation:ArticleDocumentation
    {
        .init(base: self.base)
    }
    var symbolDocumentation:SymbolDocumentation
    {
        .init(base: self.base)
    }
}

extension Fasces.Data.TopLevelArticles:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Module>>.FieldView<Set<Article>>
    {
        self.base[index].data.topLevelArticles
    }
}
extension Fasces.Data.TopLevelSymbols:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Module>>.FieldView<Set<Symbol>>
    {
        self.base[index].data.topLevelSymbols
    }
}
extension Fasces.Data.Declarations:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Symbol>>.FieldView<Declaration<Symbol>>
    {
        self.base[index].data.declarations
    }
}

extension Fasces.Data.ModuleDocumentation:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Module>>.FieldView<DocumentationExtension<Never>>
    {
        self.base[index].data.moduleDocumentation
    }
}
extension Fasces.Data.ArticleDocumentation:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Article>>.FieldView<DocumentationExtension<Never>>
    {
        self.base[index].data.articleDocumentation
    }
}
extension Fasces.Data.SymbolDocumentation:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Symbol>>.FieldView<DocumentationExtension<Symbol>>
    {
        self.base[index].data.symbolDocumentation
    }
}