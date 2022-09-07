import SymbolGraphs

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
struct Surface 
{
    private(set)
    var missingModules:Set<Branch.Position<Module>>, 
        missingSymbols:Set<Branch.Position<Symbol>>, 
        missingDiacritics:Set<Branch.Diacritic>
    
    private(set)
    var symbols:[Tree.Position<Symbol>: Symbol.Facts<Tree.Position<Symbol>>]
    private(set)
    var diacritics:[Tree.Diacritic: Symbol.Traits<Tree.Position<Symbol>>]
    
    init(branch:__shared Branch, fasces:Fasces)
    {
        self.symbols = [:]
        self.diacritics = [:]

        self.missingModules = []
        self.missingSymbols = []
        self.missingDiacritics = []

        // TODO: this should not require an unbounded range slice
        for module:Module in branch.modules[...] 
        {
            self.missingModules.insert(module.index)
            for (range, _):(Range<Symbol.Offset>, Branch.Position<Module>) in module.symbols 
            {
                for offset:Symbol.Offset in range 
                {
                    self.missingSymbols.insert(.init(module.index, offset: offset))
                }
            }
        }
        for (module, divergence):(Branch.Position<Module>, Module.Divergence) in 
            branch.modules.divergences
        {
            for (range, _):(Range<Symbol.Offset>, Branch.Position<Module>) in divergence.symbols 
            {
                for offset:Symbol.Offset in range 
                {
                    self.missingSymbols.insert(.init(module, offset: offset))
                }
            }
        }
        for fascis:Fascis in fasces 
        {
            for module:Module in fascis.modules 
            {
                self.missingModules.insert(module.index)
            }

            fatalError("unimplemented")
        }
    }

    mutating 
    func add(member:Tree.Position<Symbol>, to scope:Tree.Position<Symbol>)
    {
        if  scope.contemporary.culture == member.contemporary.culture 
        {
            self.symbols[scope]?.primary
                .members.insert(member)
        }
        else 
        {
            self.symbols[scope]?.accepted[member.contemporary.culture, default: .init()]
                .members.insert(member)
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

        self.missingModules.remove(symbols.culture)
        for symbol:Tree.Position<Symbol>? in symbols 
        {
            if let symbol:Tree.Position<Symbol>
            {
                self.missingSymbols.remove(symbol.contemporary)
                self.symbols[symbol] = .init(
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
        for (subject, traits):(Tree.Position<Symbol>, [Symbol.Trait<Tree.Position<Symbol>>]) in 
            opinions
        {
            let traits:Symbol.Traits<Tree.Position<Symbol>> = .init(traits, 
                as: context[global: subject].community)
            
            if  subject.package == symbols.culture.package 
            {
                self.symbols[subject]?.update(acceptedCulture: symbols.culture, with: traits)
            }
            else 
            {
                let diacritic:Tree.Diacritic = .init(host: subject, culture: symbols.culture)
                self.diacritics[diacritic] = traits
            }
        }
    }
}