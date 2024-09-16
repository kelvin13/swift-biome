import SymbolSource

extension Article:IntrinsicReference
{
    struct Intrinsic:Identifiable, Sendable
    {
        struct ID:Hashable, Sendable 
        {
            let route:Route
            
            init(_ route:Route)
            {
                self.route = route
            }
            init(_ culture:Module, _ stem:Route.Stem, _ leaf:Route.Stem)
            {
                self.init(.init(culture, stem, .init(leaf, orientation: .straight)))
            }
        }

        let id:ID 
        var path:Path

        init(id:ID, path:Path)
        {
            self.id = id
            self.path = path
        }
    }

}
extension Article.Intrinsic
{
    var name:String 
    {
        self.path.last
    }
    var route:Route 
    {
        self.id.route
    }
}


extension Article
{
    struct Divergence:Sendable
    {
        var metadata:AlternateHead<Metadata?>?
        var documentation:AlternateHead<DocumentationExtension<Never>>?

        init()
        {
            self.metadata = nil 
            self.documentation = nil
        }

        var isEmpty:Bool
        {
            if  case nil = self.metadata, 
                case nil = self.documentation
            {
                return true
            }
            else
            {
                return false
            }
        }
    }
}
extension Article.Divergence:BranchDivergence
{
    typealias Key = Article

    struct Base
    {
        var metadata:OriginalHead<Article.Metadata?>?
        var documentation:OriginalHead<DocumentationExtension<Never>>?

        init()
        {
            self.metadata = nil 
            self.documentation = nil
        }
    }

    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.metadata.revert(to: rollbacks.metadata.articles)
        self.documentation.revert(to: rollbacks.data.standaloneDocumentation)
    }
}
extension Article.Divergence.Base:IntrinsicDivergenceBase
{
    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.metadata.revert(to: rollbacks.metadata.articles)
        self.documentation.revert(to: rollbacks.data.standaloneDocumentation)
    }
}