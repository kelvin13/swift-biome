import SymbolGraphs 
import DOM
import URI

extension DocumentationExtension:Equatable where Extended:Equatable 
{
    static 
    func == (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.extends == rhs.extends && 
        lhs.card == rhs.card && 
        lhs.body == rhs.body 
    }
}
struct DocumentationExtension<Extended> 
{
    var extends:Extended?
    var errors:[any Error]
    let card:DOM.Flattened<GlobalLink.Presentation>
    let body:DOM.Flattened<GlobalLink.Presentation>

    init()
    {
        self.extends = nil
        self.errors = []
        self.card = .init()
        self.body = .init()
    }
    init(inheriting extends:Extended)
    {
        self.extends = extends 
        self.errors = []
        self.card = .init()
        self.body = .init()
    }
    fileprivate
    init(compiling _extension:__owned Extension, extending extends:Extended? = nil,
        resolver:Resolver,
        scope:LexicalScope?, 
        stems:Route.Stems)
    {
        let imports:Set<Module> = resolver.namespaces.import(_extension.metadata.imports)

        let (card, body):(DOM.Flattened<String>, DOM.Flattened<String>) = 
            _extension.rendered()
        
        var errors:[any Error] = []

        func resolve(expression:String) 
            -> DOM.Substitution<GlobalLink.Presentation, String.UTF8View>
        {
            do 
            {
                return .key(try resolver.resolve(expression: expression, 
                    imports: imports, 
                    scope: scope, 
                    stems: stems))
            }
            catch let error 
            {
                errors.append(error)
                return .segment(expression.utf8)
            }
        }

        self.extends = extends 
        self.card = card.transform(resolve(expression:))
        self.body = body.transform(resolve(expression:))
        self.errors = errors
    }
}
extension DocumentationExtension<Never> 
{
    init(errors:[any Error],
        card:DOM.Flattened<GlobalLink.Presentation>,
        body:DOM.Flattened<GlobalLink.Presentation>)
    {
        self.extends = nil
        self.errors = errors 
        self.card = card 
        self.body = body
    }
}
extension DocumentationExtension 
{
    var isEmpty:Bool 
    {
        self.card.isEmpty && self.body.isEmpty
    }
}


struct PackageDocumentation 
{
    private 
    struct Comment 
    {
        enum Node 
        {
            case inherits(Symbol)
            case extends(Symbol?, with:String)
        }

        let node:Node 
        let branch:Version.Branch 

        init(_ node:Node, branch:Version.Branch)
        {
            self.node = node 
            self.branch = branch
        }
    }

    private(set) 
    var articles:[(Article, DocumentationExtension<Never>)]
    private(set) 
    var symbols:[(Symbol, DocumentationExtension<Symbol>)]
    private(set) 
    var modules:[(Module, DocumentationExtension<Never>)]
    private(set) 
    var package:DocumentationExtension<Never>?

    init(interface:__shared PackageInterface,
        graph:__shared SymbolGraph,
        local:__shared Tree, 
        stems:__shared Route.Stems)
    {
        self.articles = []
        self.symbols = []
        self.modules = []
        self.package = nil

        var comments:[Symbol: Comment] = [:]
        for (culture, interface):(SymbolGraph.Culture, ModuleInterface) in 
            zip(graph.cultures, interface)
        {
            for (position, comment):(AtomicPosition<Symbol>?, SymbolGraph.Comment<Int>) in 
                zip(interface.citizens, culture.comments)
            {
                guard let position:AtomicPosition<Symbol> = position
                else
                {
                    continue 
                }

                assert(position.culture == interface.culture)
                
                switch 
                (
                    comment.string, 
                    comment.extends.flatMap { interface.symbols[$0]?.atom }
                )
                {
                case (nil, nil): 
                    continue 
                
                case (let comment?, nil):
                    comments[position.atom] = .init(.extends(nil, with: comment), 
                        branch: position.branch)
                
                case (let comment?, let origin?):
                    comments[position.atom] = .init(.extends(origin, with: comment), 
                        branch: position.branch)
                
                case (nil, let origin?):
                    comments[position.atom] = .init(.inherits(origin), 
                        branch: position.branch)
                }
            }
        }

        self.compile(comments: _move comments, interface: interface, graph: graph,
            local: .init(local, version: interface.version), 
            stems: stems)
    }
    private mutating 
    func compile(comments:__owned [Symbol: Comment], 
        interface:PackageInterface, 
        graph:SymbolGraph,
        local:Tree.Pinned, 
        stems:Route.Stems)
    {
        var resolvers:[Module: Resolver] = .init(minimumCapacity: graph.cultures.count)
        for (_, interface):(SymbolGraph.Culture, ModuleInterface) in 
            zip(graph.cultures, interface)
        {
            // use the interface-level pins and not the package-level pins, 
            // to reduce the size of the search context
            let resolver:Resolver = .init(local: local, context: interface.context)

            for (position, _extension):(AtomicPosition<Article>?, Extension) in 
                zip(interface.articles, interface._cachedMarkdown)
            {
                // TODO: handle merge behavior block directive 
                if let position:AtomicPosition<Article> 
                {
                    self.articles.append((position.atom, .init(
                        compiling: _move _extension, 
                        resolver: resolver, 
                        scope: .init(interface.culture), 
                        stems: stems)))
                }
                else if let binding:String = _extension.binding, 
                        let binding:URI = try? .init(relative: binding),
                        let binding:_SymbolLink = try? .init(binding)
                {
                    let binding:_SymbolLink.Resolution? = local.resolve(binding.revealed.disambiguated(), 
                        scope: .init(interface.culture), 
                        stems: stems)
                    {
                        local.exists($0) && 
                        binding.disambiguator.matches($0, context: resolver.context)
                    }
                    switch binding
                    {
                    case nil: 
                        print("warning: documentation extension has no resolved binding, skipping")
                        continue 
                    
                    // case .package(_): 
                    //     self.package = .init(compiling: _move _extension, 
                    //         resolver: resolver, 
                    //         scope: nil, 
                    //         stems: stems)
                    
                    case .module(let module): 
                        self.modules.append((module, .init(compiling: _move _extension, 
                            resolver: resolver, 
                            scope: .init(module), 
                            stems: stems)))
                    
                    case .composite(let composite):
                        guard   let symbol:Symbol = composite.atom 
                        else 
                        {
                            print("warning: documentation extensions for composite APIs are unsupported, skipping")
                            continue 
                        }
                        if case .extends? = comments[symbol]?.node
                        {
                            print("warning: documentation extension would overwrite existing documentation, skipping")
                            continue 
                        }
                        guard   let plural:AtomicPosition<Symbol> = 
                                    symbol.positioned(bisecting: local.symbols)
                        else 
                        {
                            fatalError("unreachable")
                        }
                        self.symbols.append((symbol, .init(compiling: _move _extension, 
                            resolver: resolver,
                            scope: .init(local.tree[local: plural]), 
                            stems: stems)))
                    
                    case .composites(_):
                        print("warning: documentation extension has multiple possible bindings, skipping")
                        continue  
                    }
                }
            }

            resolvers[interface.culture] = resolver
        }
        self.compile(comments: _move comments, resolvers: _move resolvers, stems: stems)
    }
    private mutating 
    func compile(comments:__owned [Symbol: Comment],
        resolvers:__owned [Module: Resolver], 
        stems:Route.Stems)
    {
        for (element, comment):(Symbol, Comment) in comments 
        {
            guard let resolver:Resolver = resolvers[element.culture] 
            else 
            {
                fatalError("unreachable")
            }

            let documentation:DocumentationExtension<Symbol>
            switch comment.node 
            {
            case .inherits(let origin):
                documentation = .init(inheriting: origin)
            
            case .extends(let origin, with: let markdown):
                let _extension:Extension = .init(markdown: markdown)
                let symbol:Symbol.Intrinsic = 
                    resolver.local.tree[local: element.positioned(comment.branch)]
                documentation = .init(compiling: _extension, extending: origin, 
                    resolver: resolver,
                    scope: .init(symbol), 
                    stems: stems)
            }
            self.symbols.append((element, documentation))
        }
    }
}
