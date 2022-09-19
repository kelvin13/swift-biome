extension Module:BranchElement
{
    struct Metadata:Equatable, Sendable 
    {
        let dependencies:Set<Position<Module>>

        init(dependencies:Set<Position<Module>>)
        {
            self.dependencies = dependencies
        }
        init(namespaces:__shared Namespaces)
        {
            self.init(dependencies: namespaces.dependencies())
        }
    }

    public 
    struct Divergence:Voidable, Sendable 
    {
        var symbols:[(range:Range<Symbol.Offset>, namespace:Position<Module>)]
        var articles:[Range<Article.Offset>]

        var metadata:History<Metadata?>.Divergent?

        var topLevelArticles:History<Set<Position<Article>>>.Divergent?
        var topLevelSymbols:History<Set<Position<Symbol>>>.Divergent?
        var documentation:History<DocumentationExtension<Never>>.Divergent?
        
        init()
        {
            self.symbols = []
            self.articles = []

            self.metadata = nil
            
            self.topLevelArticles = nil
            self.topLevelSymbols = nil
            self.documentation = nil
        }
    }
}