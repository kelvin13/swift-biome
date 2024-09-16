@frozen public
struct MarkdownFile:Equatable
{
    public
    let name:String
    public
    let source:String

    public
    init(name:String, source:String)
    {
        self.name = name
        self.source = source
    }
}
