import HTML

struct ArticleCard
{
    let headline:String
    let overview:[UInt8]?
    let uri:String 

    init(headline:String, 
        overview:[UInt8]?, 
        uri:String)
    {
        self.headline = headline
        self.overview = overview
        self.uri = uri
    }
}
extension ArticleCard:HTMLElementConvertible
{
    var html:HTML.Element<Never>
    {
        let headline:HTML.Element<Never> = .a(.h2(.init(escaped: self.headline)), 
            attributes: [.href(self.uri), .class("headline")])
        let more:HTML.Element<Never> = .a("Read more", 
            attributes: [.href(self.uri), .class("more")])
        if  let utf8:[UInt8] = self.overview
        {
            return .li(headline, .init(node: .value(.init(escaped: _move utf8))), more)
        }
        else 
        {
            return .li(headline, more)
        }
    }
}