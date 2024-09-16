extension Article
{
    struct Headline:Equatable, Sendable
    {
        let formatted:String
        let plain:String 

        init(formatted:String, plain:String)
        {
            self.formatted = formatted 
            self.plain = plain 
        }

        init(markup:__shared Extension.Headline)
        {
            self.init(formatted: .init(decoding: markup.rendered(as: [UInt8].self), 
                    as: Unicode.UTF8.self), 
                plain: markup.plainText)
        }
    }
    struct Metadata:Equatable, Sendable
    {
        let headline:Headline 
        let excerpt:String 

        @available(*, deprecated, renamed: "excerpt")
        var snippet:String 
        {
            self.excerpt
        }

        init(headline:Headline, excerpt:String = "")
        {
            self.headline = headline 
            self.excerpt = excerpt
        }
        init(_extension:__shared Extension)
        {
            self.headline = .init(markup: _extension.headline)
            self.excerpt = _extension.snippet
        }
    }
}
