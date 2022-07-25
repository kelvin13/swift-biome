import Versions

extension Package 
{
    struct Pinned:Sendable 
    {
        let package:Package 
        let version:Version
        // exhibited version can be different from true version, due to 
        // implementation of historical pages. this is only used by the top-level 
        // url redirection system, content links do not use exhibitions
        let exhibit:Version?
        
        init(_ package:Package, at version:Version, exhibit:Version? = nil)
        {
            self.version = version  
            self.package = package
            self.exhibit = exhibit
        }
    }
}
extension Package.Pinned 
{
    private 
    var abbreviatedVersion:MaskedVersion? 
    {
        self.package.versions.abbreviate(self.exhibit ?? self.version)
    }
    
    private 
    func depth(of composite:Symbol.Composite, route:Route.Key) -> (host:Bool, base:Bool)
    {
        self.package.depth(of: composite, at: self.version, route: route)
    }
    
    var prefix:[String]
    {
        self.package.prefix(arrival: self.abbreviatedVersion)
    }
    var path:[String]
    {
        if let version:MaskedVersion = self.abbreviatedVersion
        {
            return [self.package.name, version.description]
        }
        else 
        {
            return [self.package.name]
        }
    }
    func path(to composite:Symbol.Composite, ecosystem:Ecosystem) -> [String]
    {
        // same as host if composite is natural
        let base:Symbol = ecosystem[composite.base]
        let host:Symbol = ecosystem[composite.diacritic.host] 
        let residency:Package.Index = host.namespace.package 
        let arrival:MaskedVersion? = 
            composite.culture.package == residency ? self.abbreviatedVersion : nil
        var path:[String] = ecosystem[residency].prefix(arrival: arrival)
        
            path.append(ecosystem[host.namespace].id.value)
        
        for component:String in host.path 
        {
            path.append(component.lowercased())
        }
        if composite.base != composite.diacritic.host
        {
            path.append(base.name.lowercased())
        }
        return path
    }
    func query(to composite:Symbol.Composite, ecosystem:Ecosystem) -> Symbol.Link.Query
    {
        // same as host if composite is natural
        let base:Symbol = ecosystem[composite.base]
        let host:Symbol = ecosystem[composite.diacritic.host] 

        var query:Symbol.Link.Query = .init()
        if composite.base != composite.diacritic.host
        {
            guard let stem:Route.Stem = host.kind.path
            else 
            {
                fatalError("unreachable: (host: \(host), base: \(base))")
            }
            
            let route:Route.Key = .init(host.namespace, stem, base.route.leaf)
            switch self.depth(of: composite, route: route)
            {
            case (host: false, base: false): 
                break 
            
            case (host: true,  base: _): 
                query.host = host.id
                fallthrough 
                
            case (host: false, base: true): 
                query.base = base.id
            }
        }
        else 
        {
            switch self.depth(of: composite, route: base.route)
            {
            case (host: _, base: false): 
                break 
            case (host: _, base: true): 
                query.base = base.id
            }
        }
        
        if composite.culture.package != host.namespace.package
        {
            query.lens = .init(self.package.id, at: self.abbreviatedVersion)
        }
        return query
    }
}
extension Package.Pinned 
{
    func template() -> Article.Template<Ecosystem.Link>
    {
        self.package.templates
            .through(self.version, head: self.package.heads.template) ?? 
            .init()
    }
    func template(_ module:Module.Index) -> Article.Template<Ecosystem.Link>
    {
        self.package.templates
            .through(self.version, head: self.package[local: module].heads.template) ?? 
            .init()
    }
    func template(_ symbol:Symbol.Index) -> Article.Template<Ecosystem.Link>
    {
        self.package.templates
            .through(self.version, head: self.package[local: symbol].heads.template) ?? 
            .init()
    }
    func template(_ article:Article.Index) -> Article.Template<Ecosystem.Link>
    {
        self.package.templates
            .through(self.version, head: self.package[local: article].heads.template) ?? 
            .init()
    }
    func excerpt(_ article:Article.Index) -> Article.Excerpt
    {
        self.package.excerpts
            .through(self.version, head: self.package[local: article].heads.excerpt) ?? 
            .init("Untitled")
    }
    
    func dependencies(_ module:Module.Index) -> Set<Module.Index>
    {
        // `nil` case should be unreachable in practice
        self.package.dependencies
            .through(self.version, head: self.package[local: module].heads.dependencies) ?? []
    }
    func toplevel(_ module:Module.Index) -> Set<Symbol.Index>
    {
        // `nil` case should be unreachable in practice
        self.package.toplevels
            .through(self.version, head: self.package[local: module].heads.toplevel) ?? []
    }
    func guides(_ module:Module.Index) -> Set<Article.Index>
    {
        self.package.guides
            .through(self.version, head: self.package[local: module].heads.guides) ?? []
    }
    
    func declaration(_ symbol:Symbol.Index) -> Declaration<Symbol.Index>
    {
        // `nil` case should be unreachable in practice
        self.package.declarations
            .through(self.version, head: self.package[local: symbol].heads.declaration) ?? 
            .init(fallback: "<unavailable>")
    }
    func facts(_ symbol:Symbol.Index) -> Symbol.Predicates 
    {
        // `nil` case should be unreachable in practice
        self.package.facts
            .through(self.version, head: self.package[local: symbol].heads.facts) ?? 
            .init(roles: nil)
    }
    
    func contains(_ composite:Symbol.Composite) -> Bool 
    {
        self.package.contains(composite, at: self.version)
    }
}
