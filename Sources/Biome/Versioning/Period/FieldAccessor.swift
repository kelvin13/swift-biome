import SymbolGraphs

struct FieldAccessor<Divergence, Value> where Divergence:BranchDivergence
{
    let alternate:WritableKeyPath<Divergence, AlternateHead<Value>?>
    let original:WritableKeyPath<Divergence.Base, OriginalHead<Value>?>
    let key:Divergence.Key

    init(_ key:Divergence.Key,
        _ original:WritableKeyPath<Divergence.Base, OriginalHead<Value>?>,
        _ alternate:WritableKeyPath<Divergence, AlternateHead<Value>?>)
    {
        self.alternate = alternate
        self.original = original 
        self.key = key 
    }
}
extension FieldAccessor<Overlay, Overlay.Metadata?>
{
    static 
    func metadata(of key:Diacritic) -> Self
    {
        .init(key, \.metadata, \.metadata)
    }
}

extension FieldAccessor<Article.Divergence, Article.Metadata?>
{
    static 
    func metadata(of key:Article) -> Self
    {
        .init(key, \.metadata, \.metadata)
    }
}
extension FieldAccessor<Article.Divergence, DocumentationExtension<Never>>
{
    static 
    func documentation(of key:Article) -> Self
    {
        .init(key, \.documentation, \.documentation)
    }
}


extension FieldAccessor<Symbol.Divergence, Symbol.Metadata?>
{
    static 
    func metadata(of key:Symbol) -> Self
    {
        .init(key, \.metadata, \.metadata)
    }
}
extension FieldAccessor<Symbol.Divergence, Declaration<Symbol>>
{
    static 
    func declaration(of key:Symbol) -> Self
    {
        .init(key, \.declaration, \.declaration)
    }
}
extension FieldAccessor<Symbol.Divergence, DocumentationExtension<Symbol>>
{
    static 
    func documentation(of key:Symbol) -> Self
    {
        .init(key, \.documentation, \.documentation)
    }
}


extension FieldAccessor<Module.Divergence, Module.Metadata?>
{
    static 
    func metadata(of key:Module) -> Self
    {
        .init(key, \.metadata, \.metadata)
    }
}
extension FieldAccessor<Module.Divergence, Set<Article>>
{
    static 
    func topLevelArticles(of key:Module) -> Self
    {
        .init(key, \.topLevelArticles, \.topLevelArticles)
    }
}
extension FieldAccessor<Module.Divergence, Set<Symbol>>
{
    static 
    func topLevelSymbols(of key:Module) -> Self
    {
        .init(key, \.topLevelSymbols, \.topLevelSymbols)
    }
}
extension FieldAccessor<Module.Divergence, DocumentationExtension<Never>>
{
    static 
    func documentation(of key:Module) -> Self
    {
        .init(key, \.documentation, \.documentation)
    }
}