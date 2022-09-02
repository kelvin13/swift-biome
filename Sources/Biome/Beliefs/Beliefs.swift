import SymbolGraphs

extension Sequence<SymbolGraph> 
{
    @available(*, deprecated)
    func generateBeliefs(abstractors:[Abstractor], context:Packages) -> Beliefs 
    {
        fatalError("obsoleted")
    }
}

struct Belief 
{
    enum Predicate 
    {
        case `is`(Symbol.Role<Tree.Position<Symbol>>)
        case has(Symbol.Trait<Tree.Position<Symbol>>)
    }

    let subject:Tree.Position<Symbol>
    let predicate:Predicate

    init(_ subject:Tree.Position<Symbol>, _ predicate:Predicate)
    {
        self.subject = subject 
        self.predicate = predicate
    }
}
struct Beliefs 
{
    var facts:[Tree.Position<Symbol>: Symbol.Facts<Tree.Position<Symbol>>]
    var opinions:[Tree.Diacritic: Symbol.Traits<Tree.Position<Symbol>>]
    
    init()
    {
        self.facts = [:]
        self.opinions = [:]
    }

    private mutating 
    func insert(_ beliefs:[Belief], symbols:_Abstractor.UpdatedSymbols, context:Packages) 
    {
        var opinions:[Tree.Position<Symbol>: [Symbol.Trait<Tree.Position<Symbol>>]] = [:]
        var traits:[Tree.Position<Symbol>: [Symbol.Trait<Tree.Position<Symbol>>]] = [:]
        var roles:[Tree.Position<Symbol>: [Symbol.Role<Tree.Position<Symbol>>]] = [:]
        for belief:Belief in beliefs 
        {
            switch (symbols.culture == belief.subject.contemporary.culture, belief.predicate)
            {
            case (false,  .is(_)):
                fatalError("unimplemented")
            case (false, .has(let trait)):
                opinions[belief.subject, default: []].append(trait)
            case (true,  .has(let trait)):
                traits[belief.subject, default: []].append(trait)
            case (true,   .is(let role)):
                roles[belief.subject, default: []].append(role)
            }
        }
        for symbol:Tree.Position<Symbol>? in symbols 
        {
            if let symbol:Tree.Position<Symbol>
            {
                self.facts[symbol] = .init(
                    traits: traits.removeValue(forKey: symbol) ?? [], 
                    roles: roles.removeValue(forKey: symbol) ?? [], 
                    as: context[global: symbol].community) 
            }
        }
        guard traits.isEmpty, roles.isEmpty 
        else 
        {
            fatalError("unimplemented")
        }
        for (symbol, traits):(Tree.Position<Symbol>, [Symbol.Trait<Tree.Position<Symbol>>]) in 
            opinions
        {
            let diacritic:Tree.Diacritic = .init(host: symbol, culture: symbols.culture)
            self.opinions[diacritic] = .init(traits, as: context[global: symbol].community)
        }
    }

    mutating 
    func update(with edges:[SymbolGraph.Edge<Int>], abstractor:_Abstractor, context:Packages)
    {
        let (beliefs, errors):([Belief], [_Abstractor.LookupError]) = 
            abstractor.translate(edges: edges, context: context)
        
        if !errors.isEmpty 
        {
            print("warning: dropped \(errors.count) edges")
        }
        
        self.insert(beliefs, symbols: abstractor.updatedSymbols, context: context)
    }

    mutating 
    func integrate() 
    {
        self.opinions = self.opinions.filter 
        {
            if $0.key.host.package == $0.key.culture.package, 
                case ()? = self.facts[$0.key.host]?.predicates.updateAcceptedTraits($0.value, 
                    culture: $0.key.culture)
            {
                return false 
            }
            else 
            {
                return true 
            }
        }
    }
}
extension Beliefs 
{
    func generateTrees(context:Packages) -> Route.Trees
    {
        var natural:[Route.NaturalTree] = []
        var synthetic:[Route.SyntheticTree] = []
        for (symbol, facts):(Tree.Position<Symbol>, Symbol.Facts<Tree.Position<Symbol>>) in 
            self.facts
        {
            let host:Symbol = context[global: symbol]
            
            natural.append(.init(key: host.route, target: symbol.index))
            
            if let stem:Route.Stem = host.kind.path
            {
                for (culture, features):(Module.Index?, Set<Tree.Position<Symbol>>) in 
                    facts.predicates.featuresAssumingConcreteType()
                {
                    synthetic.append(.init(namespace: host.namespace, stem: stem,
                        diacritic: .init(host: symbol.index, culture: culture ?? symbol.index.module), 
                        features: features.map { ($0.index, context[global: $0].route.leaf) }))
                } 
            }
        }
        for (diacritic, traits):(Tree.Diacritic, Symbol.Traits<Tree.Position<Symbol>>) in 
            self.opinions
        {
            // can have external traits that do not have to do with features
            if !traits.features.isEmpty 
            {
                let host:Symbol = context[global: diacritic.host]
                if let stem:Route.Stem = host.kind.path
                {
                    // synthetic.append(.init(namespace: host.namespace, stem: stem, 
                    //     diacritic: diacritic, 
                    //     features: traits.features.map { ($0.index, context[global: $0].route.leaf) }))
                }
            }
        }
        return (natural, synthetic)
    }
}