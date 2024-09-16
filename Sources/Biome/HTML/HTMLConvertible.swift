import HTML 

protocol HTMLConvertible<RenderedHTML>
{
    associatedtype RenderedHTML:Collection<HTML.Element<Never>>

    var htmls:RenderedHTML { get }
}

protocol HTMLOptionalConvertible:HTMLConvertible<[HTML.Element<Never>]>
{
    var html:HTML.Element<Never>? { get }
}
extension HTMLOptionalConvertible 
{
    var htmls:[HTML.Element<Never>]
    {
        self.html.map { [$0] } ?? []
    }
}

protocol HTMLElementConvertible:HTMLConvertible<CollectionOfOne<HTML.Element<Never>>>
{
    var html:HTML.Element<Never> { get }
}
extension HTMLElementConvertible 
{
    var htmls:CollectionOfOne<HTML.Element<Never>>
    {
        .init(self.html)
    }
}