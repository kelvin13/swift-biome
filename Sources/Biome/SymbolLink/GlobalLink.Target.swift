extension GlobalLink 
{
    enum Target:Hashable, Sendable 
    {
        case article(Article)
        case module(Module)
        case package(Package)
        case composite(Composite)

        init(_ resolution:_SymbolLink.Resolution?) throws 
        {
            switch resolution 
            {
            case nil: 
                throw _SymbolLink.ResolutionProblem.noResults
            case .module(let module): 
                self = .module(module)
            case .composite(let composite): 
                self = .composite(composite)
            case .composites(let composites): 
                throw _SymbolLink.ResolutionProblem.multipleResults(composites)
            }
        }
    }
}