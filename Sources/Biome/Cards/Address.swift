import SymbolSource
import URI

struct Address 
{
    enum DisambiguationLevel 
    {
        case never 
        case minimally 
        case maximally 
    }

    var function:Service.PublicFunction? 
    var global:Global

    init(_ global:Global, function:Service.PublicFunction?)
    {
        self.global = global
        self.function = function
    }

    struct Global
    {
        var residency:PackageIdentifier?
        var version:VersionSelector?
        var local:Local?

        init(_ local:Local?, residency:PackageIdentifier?, version:VersionSelector?)
        {
            self.residency = residency
            self.version = version
            self.local = local
        }
    }
    struct Local
    {
        var namespace:ModuleIdentifier 
        var symbolic:Symbolic?

        init(_ symbolic:Symbolic?, namespace:ModuleIdentifier)
        {
            self.namespace = namespace 
            self.symbolic = symbolic
        }
    }
    struct Symbolic 
    {
        var orientation:_SymbolLink.Orientation 
        var path:Path 
        var host:SymbolIdentifier? 
        var base:SymbolIdentifier?
        var nationality:_SymbolLink.Nationality?

        init(path:Path, orientation:_SymbolLink.Orientation)
        {
            self.orientation = orientation 
            self.path = path 
            self.host = nil 
            self.base = nil 
            self.nationality = nil 
        }
    }
}

extension Address.Global 
{
    fileprivate 
    init(_ local:Address.Local?, residency:__shared Tree.Pinned)
    {
        self.init(_move local, 
            residency: residency.nationality.isCommunityPackage ? residency.tree.id : nil, 
            version: residency.selector)
    }
} 
extension Address 
{
    /// Creates an address for the specified package.
    /// 
    /// The returned address always includes the package name, even if it is the 
    /// standard library or one of the core libraries.
    init(residency:__shared Tree.Pinned)
    {
        self.init(.init(nil, residency: residency.tree.id, version: residency.selector), 
            function: .documentation(.symbol))
    }
    init(residency:__shared Tree.Pinned, 
        namespace:__shared Module.Intrinsic)
    {
        self.init(.init(.init(nil, namespace: namespace.id), residency: residency), 
            function: namespace.isFunction ? nil : .documentation(.symbol))
    }
    init(residency:__shared Tree.Pinned, 
        namespace:__shared Module.Intrinsic, 
        article:__shared Article.Intrinsic)
    {
        self.init(.init(.init(.init(path: article.path, orientation: .straight), 
                namespace: namespace.id), 
                residency: residency), 
            function: namespace.isFunction ? nil : .documentation(.doc))
    }
}
extension Address 
{
    init?(_ symbolic:Symbolic, namespace:Module, context:__shared some PackageContext)
    {
        if  let residency:Tree.Pinned = context[namespace.nationality],
            let namespace:Module.Intrinsic = residency.load(local: namespace)
        {
            self.init(.init(.init(_move symbolic, namespace: namespace.id), 
                residency: residency), 
                function: .documentation(.symbol))
        }
        else
        {
            return nil
        }
    }
}

extension Address 
{
    func uri(functions:Service.PublicFunctionNames) -> URI 
    {
        var uri:URI 
        if let function:Service.PublicFunction = self.function 
        {
            uri = functions.uri(function)

            if let residency:PackageIdentifier = self.global.residency 
            {
                uri.path.append(component: residency.string)
            }
            if let version:VersionSelector = self.global.version 
            {
                uri.path.append(component: version.description)
            }
        }
        else 
        {
            uri = .init()
        }
        if let local:Local = self.global.local 
        {
            if let symbolic:Symbolic = local.symbolic 
            {
                uri.path.append(first: local.namespace.value, 
                    lowercasing: symbolic.path, 
                    orientation: symbolic.orientation)
                
                if let base:SymbolIdentifier = symbolic.base
                {
                    uri.insert(parameter: (GlobalLink.Parameter.base.rawValue, base.string))
                }
                if let host:SymbolIdentifier = symbolic.host
                {
                    uri.insert(parameter: (GlobalLink.Parameter.host.rawValue, host.string))
                }
                if let nationality:_SymbolLink.Nationality = symbolic.nationality
                {
                    let value:String 
                    if let version:VersionSelector = nationality.version 
                    {
                        value = "\(nationality.id.string)/\(version.description)"
                    }
                    else 
                    {
                        value = nationality.id.string
                    }
                    uri.insert(parameter: (GlobalLink.Parameter.nationality.rawValue, value))
                }
            }
            else 
            {
                uri.path.append(component: local.namespace.value)
            }
        }
        
        return uri 
    }
}

extension RangeReplaceableCollection where Element == URI.Vector? 
{
    fileprivate mutating 
    func append(first:String, lowercasing path:Path, orientation:_SymbolLink.Orientation)
    {
        guard case .gay = orientation
        else 
        {
            self.append(component: first)
            self.append(components: path.lazy.map { $0.lowercased() })
            return 
        }
        
        let penultimate:String 
        if let last:String = path.prefix.last 
        {
            self.append(component: first)
            self.append(components: path.prefix.dropLast().lazy.map { $0.lowercased() })

            penultimate = last.lowercased() 
        }
        else 
        {
            penultimate = first 
        }
        
        self.append(component: "\(penultimate).\(path.last.lowercased())")
    }
}