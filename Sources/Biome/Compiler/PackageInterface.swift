import SymbolGraphs
import SymbolSource

struct PackageInterface
{
    let local:Fasces
    let version:Version
    private
    var cultures:[BasisElement]
    private
    var symbols:[AtomicPosition<Symbol>?]

    init(context:PackageUpdateContext, commit:Commit,
        branch:Version.Branch, 
        graph:__shared SymbolGraph,
        stems:inout Route.Stems,
        tree:inout Tree)
    {
        self.cultures = []
        self.cultures.reserveCapacity(graph.cultures.count)

        self.symbols = []
        self.symbols.reserveCapacity(graph.identifiers.table.count)

        self.local = context.local

        for (culture, context):(SymbolGraph.Culture, ModuleUpdateContext) in 
            zip(graph.cultures, context)
        {
            let visible:Set<Module> = context.namespaces.import()
            let (articles, _extensions):([AtomicPosition<Article>?], [Extension]) = tree[branch].addExtensions(from: culture, 
                namespace: context.module, 
                trunk: context.local.articles, 
                stems: &stems)
            let symbols:[AtomicPosition<Symbol>?] = tree[branch].addSymbols(from: culture, 
                visible: visible,
                context: context,
                stems: &stems)
            
            assert(articles.count == culture.markdown.count)
            assert(symbols.count == culture.count)

            assert(self.symbols.endIndex == culture.startIndex)
            self.symbols.append(contentsOf: symbols)
            assert(self.symbols.endIndex == culture.endIndex)

            self.cultures.append(.init(articles: articles, symbols: culture.indices, 
                _cachedMarkdown: _extensions, 
                context: context))
        }
        // external symbols
        for (cohort, context):(ArraySlice<SymbolIdentifier>, ModuleUpdateContext) in 
            zip(graph.identifiers.external, context)
        {
            // not worth caching this
            let visible:Set<Module> = context.namespaces.import()
            self.symbols.append(contentsOf: cohort.lazy.map
            {
                for upstream:Tree.Pinned in context.upstream.values 
                {
                    if  let upstream:AtomicPosition<Symbol> = upstream.symbols.find($0), 
                            visible.contains(upstream.culture)
                    {
                        return upstream
                    }
                }
                return nil 
            })
        }

        assert(self.symbols.count == graph.identifiers.table.count)

        self.version = tree.commit(commit, to: branch, pins: context.pins())
    }

    var revision:Version.Revision
    {
        self.version.revision
    }
    var branch:Version.Branch
    {
        self.version.branch
    }
}
extension PackageInterface:RandomAccessCollection
{
    var startIndex:Int
    {
        self.cultures.startIndex
    }
    var endIndex:Int
    {
        self.cultures.endIndex
    }
    subscript(index:Int) -> ModuleInterface
    {
        let element:BasisElement = self.cultures[index]
        let symbols:ModuleInterface.SymbolPositions = .init(self.symbols, 
            citizens: element.symbols)
        return .init(context: .init(namespaces: element.namespaces, 
                upstream: element.upstream, 
                local: self.local), 
            _extensions: element._cachedMarkdown, 
            articles: element.articles,
            symbols: symbols)
    }
}
extension PackageInterface
{
    private
    struct BasisElement
    {
        let namespaces:Namespaces
        let upstream:[Package: Tree.Pinned]

        let articles:[AtomicPosition<Article>?]
        let symbols:Range<Int>

        // this does not belong here! once AOT article rendering lands in the `SymbolGraphs` module, 
        // we can get rid of it
        let _cachedMarkdown:[Extension]

        init(articles:[AtomicPosition<Article>?], symbols:Range<Int>, 
            _cachedMarkdown:[Extension],
            context:__shared ModuleUpdateContext)
        {
            self.namespaces = context.namespaces
            self.upstream = context.upstream

            self.articles = articles
            self.symbols = symbols
            self._cachedMarkdown = _cachedMarkdown
        }
    }
}