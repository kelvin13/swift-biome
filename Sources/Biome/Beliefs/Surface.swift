struct Belief 
{
    enum Predicate 
    {
        case `is`(Symbol.Role<PluralPosition<Symbol>>)
        case has(Symbol.Trait<PluralPosition<Symbol>>)
    }

    let subject:PluralPosition<Symbol>
    let predicate:Predicate

    init(_ subject:PluralPosition<Symbol>, _ predicate:Predicate)
    {
        self.subject = subject 
        self.predicate = predicate
    }
}

struct Surface 
{
    var articles:Set<Position<Article>>
    var symbols:Set<Position<Symbol>>
    var modules:Set<Position<Module>>
    var foreign:Set<Diacritic>

    init(articles:Set<Position<Article>> = [],
        symbols:Set<Position<Symbol>> = [],
        modules:Set<Position<Module>> = [],
        foreign:Set<Diacritic> = [])
    {
        self.articles = articles
        self.symbols = symbols
        self.modules = modules
        self.foreign = foreign
    }
}
