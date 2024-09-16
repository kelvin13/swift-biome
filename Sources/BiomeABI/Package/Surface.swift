@frozen public
struct Surface
{
    public
    var articles:[Article]
    public
    var symbols:[Symbol]
    public
    var modules:[Module]
    public
    var overlays:[Diacritic]

    @inlinable public
    init(articles:[Article] = [],
        symbols:[Symbol] = [],
        modules:[Module] = [],
        overlays:[Diacritic] = [])
    {
        self.articles = articles
        self.symbols = symbols
        self.modules = modules
        self.overlays = overlays
    }
}