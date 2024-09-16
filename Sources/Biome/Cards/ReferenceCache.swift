import HTML 
import DOM
import SymbolSource

struct ArticleReference 
{
    let metadata:Article.Metadata
    let path:Path
    let uri:String

    var headline:Article.Headline 
    {
        self.metadata.headline
    }
}
struct PackageReference 
{
    let name:PackageIdentifier 
    let uri:String

    init(name:PackageIdentifier, uri:String)
    {
        self.name = name 
        self.uri = uri
    }

    init(_ pinned:__shared Tree.Pinned, functions:__shared Service.PublicFunctionNames)
    {
        self.name = pinned.tree.id 
        self.uri = Address.init(residency: pinned).uri(functions: functions).description
    }
}
struct ModuleReference 
{
    let name:ModuleIdentifier 
    let uri:String

    // var path:Path 
    // {
    //     .init(last: self.name.string)
    // }
}
struct SymbolReference 
{
    let scope:Symbol.Scope?
    let display:Symbol.Intrinsic.Display
    let namespace:Module
    let uri:String 

    var name:String 
    {
        self.display.name
    }
    var path:Path 
    {
        self.display.path
    }
    var shape:Shape 
    {
        self.display.shape
    }
}
struct CompositeReference 
{
    let base:SymbolReference 
    let key:Organizer.SortingKey
    let uri:String
}

extension PackageReference 
{
    var html:HTML.Element<Never> 
    {
        .a(self.name.string, attributes: [.href(self.uri)])
    }
}
extension ModuleReference 
{
    var html:HTML.Element<Never> 
    {
        .a(self.name.string, attributes: [.href(self.uri)])
    }
}
extension ArticleReference 
{
    var html:HTML.Element<Never> 
    {
        return .a(.init(escaped: self.headline.formatted), attributes: [.href(self.uri)])
    }
}

struct SymbolReferenceError:Error
{
    let key:Symbol

    init(_ key:Symbol)
    {
        self.key = key
    }
}

struct ReferenceCache 
{
    private 
    var articles:[Article: ArticleReference]
    private 
    var symbols:[Symbol: SymbolReference]
    private 
    var modules:[Module: ModuleReference]
    private 
    var uris:[Compound: String]
    let functions:Service.PublicFunctionNames

    init(functions:Service.PublicFunctionNames)
    {
        self.functions = functions 
        self.articles = [:]
        self.symbols = [:]
        self.modules = [:]
        self.uris = [:]
    }

    private mutating
    func miss(_ key:Module, module:Module.Intrinsic, address:Address) -> ModuleReference
    {
        let reference:ModuleReference = .init(name: module.id, 
            uri: address.uri(functions: self.functions).description)
        self.modules[key] = reference 
        return reference
    }
    private mutating
    func miss(_ key:Symbol, symbol:Symbol.Intrinsic, address:Address) -> SymbolReference
    {
        let reference:SymbolReference = .init(scope: symbol.scope, display: symbol.display, 
            namespace: symbol.namespace, 
            uri: address.uri(functions: self.functions).description)
        self.symbols[key] = reference 
        return reference
    }
    private mutating
    func miss(_ key:Article, article:Article.Intrinsic, address:Address, 
        metadata:Article.Metadata) -> ArticleReference
    {
        let reference:ArticleReference = .init(metadata: metadata, path: article.path,
            uri: address.uri(functions: self.functions).description)
        self.articles[key] = reference 
        return reference
    }
}

extension ReferenceCache 
{
    mutating 
    func load(_ composite:Composite, context:some PackageContext) throws -> CompositeReference
    {
        let base:SymbolReference = try self.load(composite.base, context: context)
        if  let compound:Compound = composite.compound 
        {
            let host:SymbolReference = try self.load(compound.host, context: context)
            let uri:String = try self.uri(of: compound, context: context)
            return .init(base: base, key: .compound((host.path, base.name)), uri: uri)
        }
        else 
        {
            return .init(base: base, key: .atomic(base.path), uri: base.uri)
        }
    }
}
extension ReferenceCache 
{
    mutating 
    func load(_ key:AtomicPosition<Symbol>, context:some PackageContext) throws -> SymbolReference
    {
        if  let cached:SymbolReference = self.symbols[key.atom]
        {
            return cached
        }
        if  let pinned:Tree.Pinned = context[key.nationality]
        {
            let symbol:Symbol.Intrinsic = pinned.tree[local: key]
            if  let address:Address = pinned.address(of: key.atom, symbol: symbol, 
                    context: context)
            {
                return self.miss(key.atom, symbol: symbol, address: address)
            }
        }
        fatalError("unimplemented")
    }
    mutating 
    func load(_ key:Symbol, context:some PackageContext) throws -> SymbolReference
    {
        if  let cached:SymbolReference = self.symbols[key]
        {
            return cached
        }
        if  let pinned:Tree.Pinned = context[key.nationality],
            let symbol:Symbol.Intrinsic = pinned.load(local: key), 
            let address:Address = pinned.address(of: key, symbol: symbol, 
                    context: context)
        {
            return self.miss(key, symbol: symbol, address: address)
        }
        else 
        {
            fatalError("unimplemented")
        }
    }
}
extension ReferenceCache 
{
    mutating 
    func load(_ key:AtomicPosition<Module>, context:some PackageContext) throws -> ModuleReference
    {
        if  let cached:ModuleReference = self.modules[key.atom]
        {
            return cached
        }
        if  let pinned:Tree.Pinned = context[key.nationality]
        {
            let module:Module.Intrinsic = pinned.tree[local: key]
            return self.miss(key.atom, module: module, address: .init(residency: pinned,
                namespace: module))
        }
        else 
        {
            fatalError("unimplemented")
        }
    }
    mutating 
    func load(_ key:Module, context:some PackageContext) throws -> ModuleReference
    {
        if  let cached:ModuleReference = self.modules[key]
        {
            return cached
        }
        if  let pinned:Tree.Pinned = context[key.nationality],
            let module:Module.Intrinsic = pinned.load(local: key)
        {
            return self.miss(key, module: module, address: .init(residency: pinned,
                namespace: module))
        }
        else 
        {
            fatalError("unimplemented")
        }
    }
}
extension ReferenceCache 
{
    mutating 
    func load(_ key:Article, context:some PackageContext) throws -> ArticleReference
    {
        if  let cached:ArticleReference = self.articles[key]
        {
            return cached
        }
        if  let pinned:Tree.Pinned = context[key.nationality],
            let namespace:Module.Intrinsic = pinned.load(local: key.culture),
            let article:Article.Intrinsic = pinned.load(local: key), 
            let metadata:Article.Metadata = pinned.metadata(local: key)
        {
            return self.miss(key, article: article, address: .init(residency: pinned, 
                    namespace: namespace, 
                    article: article), 
                metadata: metadata)
        }
        else 
        {
            fatalError("unimplemented")
        }
    }
}
extension ReferenceCache
{
    func load(_ package:Package, context:some PackageContext) throws -> PackageReference
    {
        if let pinned:Tree.Pinned = context[package]
        {
            return .init(pinned, functions: self.functions)
        }
        else 
        {
            fatalError("unimplemented")
        }
    }
}

extension ReferenceCache 
{
    mutating
    func uri(of composite:Composite, context:some PackageContext) throws -> String
    {
        if let compound:Compound = composite.compound 
        {
            return try self.uri(of: compound, context: context)
        }
        else 
        {
            return try self.load(composite.base, context: context).uri
        }
    }
    mutating
    func uri(of compound:Compound, context:some PackageContext) throws -> String
    {
        if      let cached:String = self.uris[compound]
        {
            return cached 
        }
        // unfortunately, we do not cache the loaded components, because 
        // we do not want to compute any uris we might not use.
        else if let address:Address = context[compound.nationality]?.address(of: compound, 
                    context: context)
        {
            let uri:String = address.uri(functions: self.functions).description
            self.uris[compound] = uri
            return uri 
        }
        else 
        {
            fatalError("unimplemented")
        }
    }
}

extension ReferenceCache 
{
    mutating 
    func link(_ prose:DOM.Flattened<GlobalLink.Presentation>, context:some PackageContext) 
        throws -> [UInt8]?
    {
        prose.isEmpty ? nil : try prose.rendered
        {
            try self.expand($0, context: context).node.rendered(as: [UInt8].self)
        }
    }

    private mutating 
    func expand(_ link:GlobalLink.Presentation, context:some PackageContext) 
        throws -> HTML.Element<Never> 
    {
        switch link 
        {
        case .composite(let composite, visible: let visible):
            return try self.expand(composite, count: visible, context: context)
        
        case .article(let article):
            return .cite(try self.load(article, context: context).html) 
        
        case .module(let module):
            return .code(try self.load(module, context: context).html)
        
        case .package(let package):
            return .code(try self.load(package, context: context).html)
        }
    }
    private mutating 
    func expand(_ link:Composite, count:Int, context:some PackageContext) 
        throws -> HTML.Element<Never>
    {
        var current:SymbolReference = try self.load(link.base, context: context)
        var crumbs:[HTML.Element<Never>] = []
            crumbs.reserveCapacity(count)
        
        if  let compound:Compound = link.compound
        {
            let uri:String = try self.uri(of: compound, context: context)
            crumbs.append(.a(current.name, attributes: [.href(uri)]))
            current = try self.load(compound.host, context: context)
        }
        while crumbs.count < count 
        {
            if !crumbs.isEmpty 
            {
                crumbs.append(.init(escaped: "."))
            }

            crumbs.append(.a(current.name, attributes: [.href(current.uri)]))

            if let next:AtomicPosition<Symbol> = current.scope?.target 
            {
                current = try self.load(next, context: context)
            }
            else if crumbs.count < count 
            {
                let module:ModuleReference = try self.load(current.namespace, context: context)
                crumbs.append(.init(escaped: "."))
                crumbs.append(module.html)
                break 
            }
            else 
            {
                break 
            }
        }
        return .code(crumbs.reversed())
    }
}