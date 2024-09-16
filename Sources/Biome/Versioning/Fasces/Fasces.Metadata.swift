extension Fasces
{
    struct Metadata
    {
        let base:Fasces
    }
    var metadata:Metadata
    {
        .init(base: self)
    }
}
extension Fasces.Metadata
{
    struct Modules:FascesView
    {
        let base:Fasces
    }
    struct Articles:FascesView
    {
        let base:Fasces
    }
    struct Symbols:FascesView
    {
        let base:Fasces
    }
    struct Overlays:FascesView
    {
        let base:Fasces
    }

    var modules:Modules
    {
        .init(base: self.base)
    }
    var articles:Articles
    {
        .init(base: self.base)
    }
    var symbols:Symbols
    {
        .init(base: self.base)
    }
    var overlays:Overlays
    {
        .init(base: self.base)
    }
}

extension Fasces.Metadata.Modules:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Module>>.FieldView<Module.Metadata?>
    {
        self.base[index].metadata.modules
    }
}
extension Fasces.Metadata.Articles:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Article>>.FieldView<Article.Metadata?>
    {
        self.base[index].metadata.articles
    }
}
extension Fasces.Metadata.Symbols:FieldViews
{
    subscript(index:Int) -> Period<IntrinsicSlice<Symbol>>.FieldView<Symbol.Metadata?>
    {
        self.base[index].metadata.symbols
    }
}
extension Fasces.Metadata.Overlays:FieldViews
{
    subscript(index:Int) -> Period<OverlayTable>.FieldView<Overlay.Metadata?>
    {
        self.base[index].metadata.overlays
    }
}