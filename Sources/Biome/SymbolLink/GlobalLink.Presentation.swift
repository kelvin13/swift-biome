extension GlobalLink
{
    enum Presentation:Hashable, Sendable
    {
        case article(Article)
        case module(Module)
        case package(Package)
        case composite(Composite, visible:Int)

        init(_ target:Target, visible:Int)
        {
            switch target 
            {
            case .article(let article):
                self = .article(article)
            case .module(let module):
                self = .module(module)
            case .package(let package):
                self = .package(package)
            case .composite(let composite):
                self = .composite(composite, visible: visible)
            }
        }
    }
}