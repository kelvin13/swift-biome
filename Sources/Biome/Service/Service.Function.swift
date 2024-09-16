import DOM
import SymbolSource
import URI 

extension Service 
{
    public 
    struct PublicFunctionNames 
    {
        var sitemap:CaselessString, 
            lunr:CaselessString, 
            doc:CaselessString,
            symbol:CaselessString
        
        init() 
        {
            self.sitemap = "sitemaps"
            self.lunr = "lunr"
            self.doc = "learn"
            self.symbol = "reference"
        }
    }
    enum PublicFunction 
    {
        case documentation(Scheme)
        case sitemap 
        case lunr

    }
    struct CustomFunction 
    {
        let nationality:Package
        // store a module identifier instead of a position or atom, 
        // to make this more resilient against version editing
        let namespace:ModuleIdentifier
        let template:DOM.Flattened<PageElement> 
    }
    enum Function 
    {
        case `public`(PublicFunction)
        case custom(CustomFunction)

        case _administrator
    }

    struct Functions 
    {
        private 
        var table:[CaselessString: Function]
        private(set)
        var names:PublicFunctionNames
        
        subscript(key:String) -> Function?
        {
            self.table[.init(key)]
        }

        init()
        {
            self.names = .init()

            self.table = 
            [
                "administrator":    ._administrator,

                self.names.sitemap: .public(.sitemap),
                self.names.lunr:    .public(.lunr),
                self.names.doc:     .public(.documentation(.doc)),
                self.names.symbol:  .public(.documentation(.symbol)),
            ]
        }
        init(_ table:[String: PublicFunction])
        {
            self.init()
            for (name, function):(String, PublicFunction) in table 
            {
                let name:CaselessString = .init(name)
                self.table[name] = .public(function)
                switch function 
                {
                case .sitemap: 
                    self.names.sitemap = name 
                case .lunr: 
                    self.names.lunr = name 
                case .documentation(.doc): 
                    self.names.doc = name 
                case .documentation(.symbol): 
                    self.names.symbol = name 
                }
            }
        }

        mutating 
        func create(_ namespace:ModuleIdentifier, 
            nationality:Package, 
            template:DOM.Flattened<PageElement>) -> Bool 
        {
            let key:CaselessString = .init(namespace) 
            if self.table.keys.contains(key)
            {
                return false 
            }
            else 
            {
                self.table[key] = .custom(.init(
                    nationality: nationality, 
                    namespace: namespace, 
                    template: template))
                return true 
            }
        }
    }
}
extension Service.PublicFunctionNames
{
    func uri(_ function:Service.PublicFunction) -> URI
    {
        switch function 
        {
        case .sitemap:                  return .init(root: self.sitemap.lowercased)
        case .lunr:                     return .init(root: self.lunr.lowercased)
        case .documentation(.doc):      return .init(root: self.doc.lowercased)
        case .documentation(.symbol):   return .init(root: self.symbol.lowercased)
        }
    }
}