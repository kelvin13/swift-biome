import SymbolSource

extension Module:IntrinsicReference
{
    struct Intrinsic:Identifiable, Sendable
    {
        let id:ModuleIdentifier
        let culture:Module
        /// Indicates if this module should be served directly from the site root. 
        var isFunction:Bool

        init(id:ModuleIdentifier, culture:Module)
        {
            self.id = id 
            self.culture = culture
            self.isFunction = false
        }
    }
}
extension Module.Intrinsic
{
    var path:Path 
    {
        .init(last: self.id.string)
    }
    var nationality:Package 
    {
        self.culture.nationality
    }
}

extension Module
{
    struct Divergence:Sendable 
    {
        // important! do not add fields without also updating the `isEmpty` definition!
        var symbols:[(range:Range<Symbol.Offset>, namespace:Module)]
        var articles:[Range<Article.Offset>]

        var metadata:AlternateHead<Metadata?>?

        var topLevelArticles:AlternateHead<Set<Article>>?
        var topLevelSymbols:AlternateHead<Set<Symbol>>?
        var documentation:AlternateHead<DocumentationExtension<Never>>?
        
        init()
        {
            self.symbols = []
            self.articles = []

            self.metadata = nil
            
            self.topLevelArticles = nil
            self.topLevelSymbols = nil
            self.documentation = nil
        }

        var isEmpty:Bool
        {
            if  case nil = self.metadata, 
                case nil = self.topLevelArticles,
                case nil = self.topLevelSymbols,
                case nil = self.documentation,
                self.symbols.isEmpty,
                self.articles.isEmpty
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
extension Module.Divergence:BranchDivergence
{
    typealias Key = Module
    
    struct Base
    {
        var metadata:OriginalHead<Module.Metadata?>?

        var topLevelArticles:OriginalHead<Set<Article>>?
        var topLevelSymbols:OriginalHead<Set<Symbol>>?
        var documentation:OriginalHead<DocumentationExtension<Never>>?

        init()
        {
            self.metadata = nil
            self.topLevelArticles = nil 
            self.topLevelSymbols = nil 
            self.documentation = nil
        }
    }

    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.metadata.revert(to: rollbacks.metadata.modules)
        self.topLevelArticles.revert(to: rollbacks.data.topLevelArticles)
        self.topLevelSymbols.revert(to: rollbacks.data.topLevelSymbols)
        self.documentation.revert(to: rollbacks.data.standaloneDocumentation)
    }
}
extension Module.Divergence.Base:IntrinsicDivergenceBase
{
    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.metadata.revert(to: rollbacks.metadata.modules)
        self.topLevelArticles.revert(to: rollbacks.data.topLevelArticles)
        self.topLevelSymbols.revert(to: rollbacks.data.topLevelSymbols)
        self.documentation.revert(to: rollbacks.data.standaloneDocumentation)
    }
}
