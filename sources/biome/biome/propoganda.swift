extension Module 
{
    struct Beliefs 
    {
        var facts:[Symbol.Index: Symbol.Facts]
        var opinions:[Package.Index: [Symbol.Index: Symbol.Traits]]
        
        init(facts:[Symbol.Index: Symbol.Facts])
        {
            self.facts = facts
            self.opinions = [:]
        }
    }
}

extension Ecosystem 
{
    typealias Opinions = [Package.Index: [Symbol.Index: [Symbol.Trait]]]
    
    mutating 
    func updateImplicitSymbols<Symbols>(in index:Package.Index, 
        fromExplicit symbols:[Symbols],
        graphs:[Module.Graph],
        scopes:[Symbol.Scope])
        throws -> [Symbol.Index: Symbol.Index]
        where Symbols:Sequence, Symbols.Element == Symbol.Index
    {
        let (speeches, hints):([[Symbol.Statement]], [Symbol.Index: Symbol.Index]) = 
            try self.generateRhetoric(graphs: graphs, scopes: scopes)
        // compute relationships
        let (facts, opinions):([Symbol.Index: Symbol.Facts], [Symbol.Diacritic: Symbol.Traits]) = 
            try self.generateBeliefs(cultures: scopes.map(\.culture), 
                about: symbols,
                from: speeches)
        
        self.updateCompositeGroups(in: index, facts: facts, opinions: opinions)
        // ``updateCompositeGroups(in:facts:opinions:)`` doesn’t read from the 
        // keyframe buffers, so it’s okay to call it before ``updateRelationships(ideology:)``.
        self[index].updateFacts(facts)
        self[index].updateOpinions(opinions)
        // pollinate opinions 
        let current:Version = self[index].latest
        for diacritic:Symbol.Diacritic in opinions.keys 
        {
            let pin:Module.Pin = .init(culture: diacritic.culture, version: current)
            self[diacritic.host.module.package].pollinate(local: diacritic.host, from: pin)
        }
        return hints
    }
    
    private 
    func generateBeliefs<Symbols>(
        cultures:[Module.Index], 
        about symbols:[Symbols],
        from speeches:[[Symbol.Statement]])
        throws -> 
        (
            facts:[Symbol.Index: Symbol.Facts], 
            opinions:[Symbol.Diacritic: Symbol.Traits]
        )
        where Symbols:Sequence, Symbols.Element == Symbol.Index
    {
        var facts:[Symbol.Index: Symbol.Facts] = [:]
        var local:[Symbol.Diacritic: Symbol.Traits] = [:]
        var opinions:[Symbol.Diacritic: Symbol.Traits] = [:]
        
        for (culture, (statements, symbols)):(Module.Index, ([Symbol.Statement], Symbols)) in 
            zip(cultures, zip(speeches, symbols))
        {
            var traits:[Symbol.Index: [Symbol.Trait]] = [:]
            var predicates:[Symbol.Index: [Symbol.Predicate]] = [:]
            for (subject, predicate):Symbol.Statement in statements 
            {
                switch (culture == subject.module, predicate)
                {
                case (false,  .is(let role)):
                    throw AuthorityError.externalSymbol(subject, is: role, accordingTo: culture)
                case (false, .has(let trait)):
                    traits[subject, default: []].append(trait)
                case (true,       let predicate):
                    predicates[subject, default: []].append(predicate)
                }
            }
            for symbol:Symbol.Index in symbols 
            {
                facts[symbol] = try .init(
                    validating: predicates.removeValue(forKey: symbol) ?? [], 
                    as: self[symbol].color)
            }
            for (symbol, traits):(Symbol.Index, [Symbol.Trait]) in traits 
            {
                let diacritic:Symbol.Diacritic = .init(host: symbol, culture: culture)
                let traits:Symbol.Traits = .init(traits, as: self[symbol].color)
                if symbol.module.package == culture.package 
                {
                    local[diacritic] = traits 
                }
                else 
                {
                    opinions[diacritic] = traits
                }
            }
        }
        for (diacritic, traits):(Symbol.Diacritic, Symbol.Traits) in local 
        {
            if  let index:Dictionary<Symbol.Index, Symbol.Facts>.Index = 
                facts.index(forKey: diacritic.host)
            {
                assert(diacritic.host.module != diacritic.culture)
                facts.values[index].external[diacritic.culture] = traits 
            }
        }
        
        return (facts, opinions)
    }
    
    private 
    func generateRhetoric(graphs:[Module.Graph], scopes:[Symbol.Scope])
        throws -> (speeches:[[Symbol.Statement]], hints:[Symbol.Index: Symbol.Index])
    {
        var uptree:[Symbol.Index: Symbol.Index] = [:]
        var speeches:[[Symbol.Statement]] = [] 
            speeches.reserveCapacity(scopes.count)
        for (graph, scope):(Module.Graph, Symbol.Scope) in zip(graphs, scopes)
        {
            // if we have `n` edges, we will get between `n` and `2n` statements
            var statements:[Symbol.Statement] = []
                statements.reserveCapacity(graph.edges.reduce(0) { $0 + $1.count })
            for edge:Edge in graph.edges.joined()
            {
                var constraints:Set<Generic.Constraint<Symbol.Index>> = []
                for constraint:Generic.Constraint<Symbol.ID> in edge.constraints
                {
                    constraints.insert(try constraint.map(scope.index(of:)))
                }
                let (source, target):(Symbol.Index, Symbol.Index) = 
                (
                    try scope.index(of: edge.source),
                    try scope.index(of: edge.target)
                )
                
                switch try self.generateStatements(
                    when: source, is: edge.kind, of: target, where: constraints)
                {
                case (let source?,  let target):
                    statements.append(source)
                    statements.append(target)
                case (nil,          let target):
                    statements.append(target)
                }
                
                // don’t care about hints for symbols in other packages
                if  source.module.package == scope.culture.package, 
                    let origin:Symbol.ID = edge.origin, 
                // this fails quite frequently. we don’t have a great solution for this.
                    let origin:Symbol.Index = try? scope.index(of: origin), origin != source
                {
                    uptree[source] = origin
                }
            }
            speeches.append(statements)
        }
        
        // flatten the uptree, in O(n). every item in the dictionary will be 
        // visited at most twice.
        for index:Dictionary<Symbol.Index, Symbol.Index>.Index in uptree.indices 
        {
            var crumbs:Set<Dictionary<Symbol.Index, Symbol.Index>.Index> = []
            var current:Dictionary<Symbol.Index, Symbol.Index>.Index = index
            while let union:Dictionary<Symbol.Index, Symbol.Index>.Index = 
                uptree.index(forKey: uptree.values[current])
            {
                assert(current != union)
                
                crumbs.update(with: current)
                current = union
                
                if crumbs.contains(union)
                {
                    fatalError("detected cycle in doccomment uptree")
                }
            }
            for crumb:Dictionary<Symbol.Index, Symbol.Index>.Index in crumbs 
            {
                uptree.values[crumb] = uptree.values[current]
            }
        }
        return (speeches, uptree)
    }
    
    private 
    func generateStatements(
        when source:Symbol.Index, is label:Edge.Kind, of target:Symbol.Index, 
        where constraints:Set<Generic.Constraint<Symbol.Index>>)
        throws -> (source:Symbol.Statement?, target:Symbol.Statement)
    {
        switch  
        (
                self[source].color,
            is: label,
            of: self[target].color,
            unconditional: constraints.isEmpty
        ) 
        {
        case    (.callable(_),      is: .feature,               of: .concretetype(_),   unconditional: true):
            return
                (
                    nil,
                    (target, .has(.feature(source)))
                )
        
        case    (.concretetype(_),  is: .member,                of: .concretetype(_),   unconditional: true), 
                (.typealias,        is: .member,                of: .concretetype(_),   unconditional: true), 
                (.callable(_),      is: .member,                of: .concretetype(_),   unconditional: true), 
                (.concretetype(_),  is: .member,                of: .protocol,          unconditional: true),
                (.typealias,        is: .member,                of: .protocol,          unconditional: true),
                (.callable(_),      is: .member,                of: .protocol,          unconditional: true):
            return 
                (
                    (source,  .is(.member(of: target))), 
                    (target, .has(.member(    source)))
                )
        
        case    (.concretetype(_),  is: .conformer,             of: .protocol,          unconditional: _):
            return 
                (
                    (source, .has(.conformance(target, where: constraints))), 
                    (target, .has(  .conformer(source, where: constraints)))
                )
         
        case    (.protocol,         is: .conformer,             of: .protocol,          unconditional: true):
            return 
                (
                    (source,  .is(.refinement(of: target))), 
                    (target, .has(.refinement(    source)))
                ) 
        
        case    (.class,            is: .subclass,              of: .class,             unconditional: true):
            return 
                (
                    (source,  .is(.subclass(of: target))), 
                    (target, .has(.subclass(    source)))
                ) 
         
        case    (.associatedtype,   is: .override,              of: .associatedtype,    unconditional: true),
                (.callable(_),      is: .override,              of: .callable,          unconditional: true):
            return 
                (
                    (source,  .is(.override(of: target))), 
                    (target, .has(.override(    source)))
                ) 
         
        case    (.associatedtype,   is: .requirement,           of: .protocol,          unconditional: true),
                (.callable(_),      is: .requirement,           of: .protocol,          unconditional: true),
                (.associatedtype,   is: .optionalRequirement,   of: .protocol,          unconditional: true),
                (.callable(_),      is: .optionalRequirement,   of: .protocol,          unconditional: true):
            return 
                (
                    (source,  .is(.requirement(of: target))), 
                    (target,  .is(  .interface(of: source)))
                ) 
         
        case    (.callable(_),      is: .defaultImplementation, of: .callable(_),       unconditional: true):
            return 
                (
                    (source,  .is(.implementation(of: target))), 
                    (target, .has(.implementation(    source)))
                ) 
        
        case (_, is: _, of: _, unconditional: false):
            // ``Edge.init(from:)`` should have thrown a ``JSON.LintingError`
            fatalError("unreachable")
        
        case (let source, is: let label, of: let target, unconditional: true):
            throw Symbol.RelationshipError.miscegenation(source, cannotBe: label, of: target)
        }
    }
}

extension Ecosystem 
{
    // also updates the symbol groups
    mutating 
    func updateCompositeGroups(in index:Package.Index, 
        facts:[Symbol.Index: Symbol.Facts], 
        opinions:[Symbol.Diacritic: Symbol.Traits])
    {
        for (host, facts):(Symbol.Index, Symbol.Facts) in facts
        {
            assert(host.module.package == index)
            
            let symbol:Symbol = self[host]
            
            self[index].groups.insert(natural: host, at: symbol.route)
            
            guard let path:Route.Stem = symbol.kind.path
            else 
            {
                continue 
            }
            for (culture, features):(Module.Index?, Set<Symbol.Index>) in 
                facts.featuresAssumingConcreteType()
            {
                self[index].groups.insert(
                    diacritic: .init(host: host, culture: culture ?? host.module), 
                    features: features.map { ($0, self[$0].route.leaf) }, 
                    under: (symbol.namespace, path))
            }
        }
        for (diacritic, traits):(Symbol.Diacritic, Symbol.Traits) in opinions
        {
            assert(diacritic.host.module.package != index)
            
            let symbol:Symbol = self[diacritic.host]
            
            guard let path:Route.Stem = symbol.kind.path
            else 
            {
                // can have external traits that do not have to do with features
                continue 
            }
            if !traits.features.isEmpty
            {
                self[index].groups.insert(diacritic: diacritic, 
                    features: traits.features.map { ($0, self[$0].route.leaf) }, 
                    under: (symbol.namespace, path))
            }
        }
        
        print("(\(self[index].id)) found \(self[index].groups._count) addressable endpoints")
    }
}
