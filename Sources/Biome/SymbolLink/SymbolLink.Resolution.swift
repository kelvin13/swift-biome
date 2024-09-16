extension _SymbolLink 
{
    enum ResolutionProblem:Error 
    {
        case empty
        case scheme 
        case residency
        // case residentVersion
        case nationality
        case nationalVersion

        case noResults
        case multipleResults([Composite])
    }
    
    struct ResolutionError:Error 
    {
        let link:String 
        let problem:any Error 

        init(_ link:String, _ error:any Error)
        {
            self.link = link 
            self.problem = error
        }
        init(_ link:String, problem:ResolutionProblem)
        {
            self.link = link 
            self.problem = problem
        }
    }

    enum Resolution 
    {
        //case package(Package)
        case module(Module)
        case composite(Composite) 
        case composites([Composite]) 

        init(_ selection:Selection<Composite>)
        {
            switch selection 
            {
            case .one(let composite): 
                self = .composite(composite)
            case .many(let composites): 
                self = .composites(composites)
            }
        }
    }
}