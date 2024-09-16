import SymbolSource
import URI

struct _SymbolLink:RandomAccessCollection
{
    struct Path:RandomAccessCollection 
    {
        private
        var components:[Component]
        private(set)
        var startIndex:Int
        private(set)
        var orientation:Orientation
        
        var endIndex:Int 
        {
            self.components.endIndex
        }
        subscript(index:Int) -> Component
        {
            _read 
            {
                yield  self.components[index]
            }
            _modify
            {
                yield &self.components[index]
            }
        }

        var first:Component 
        {
            _read 
            {
                yield  self.components[self.startIndex]
            }
            _modify 
            {
                yield &self.components[self.startIndex]
            }
        }
        var last:Component 
        {
            _read 
            {
                yield  self.components[self.index(before: self.endIndex)]
            }
            _modify 
            {
                yield &self.components[self.index(before: self.endIndex)]
            }
        }

        init?(_ components:some Collection<some StringProtocol>) throws 
        {
            try self.init(components: components, fold: components.startIndex)
        }
        init?(_ vectors:some Collection<URI.Vector?>) throws 
        {
            let (components, fold):([String], Int) = vectors.normalized 
            try self.init(components: components, fold: fold)
        }
        init?<Path>(components:Path, fold:Path.Index) throws
            where Path:Collection, Path.Element:StringProtocol
        {
            // iii. semantic segmentation 
            //
            // [     'foo',       'bar',       'baz.bar',                     '.Foo',          '..'] becomes
            // [.big("foo"), .big("bar"), .big("baz"), .little("bar"), .little("Foo"), .little("..")] 
            //                                                                         ^~~~~~~~~~~~~~~
            //                                                                          (visible = 1)
            self.orientation = .straight
            self.components = []
            self.components.reserveCapacity(components.underestimatedCount)
            self.startIndex = self.components.startIndex 
            // it is valid to pass an index for `fold` that is outside the bounds of 
            // the components collection!
            if components.startIndex < fold
            {
                try self.append(components: components[..<fold])
                self.startIndex = self.components.endIndex
                try self.append(components: components[fold...])
            }
            else 
            {
                try self.append(components: components)
            }
            if self.isEmpty 
            {
                return nil 
            }
        }

        var revealed:Self 
        {
            var revealed:Self = self 
                revealed.startIndex = revealed.components.startIndex 
            return revealed
        }
        var suffix:Self?
        {
            var suffix:Self = self 
                suffix.startIndex += 1
            return suffix.startIndex < suffix.endIndex ? suffix : nil
        }
        var outed:Self? 
        {
            switch self.orientation 
            {
            case .gay: 
                return nil 
            case .straight: 
                var outed:Self = self 
                    outed.orientation = .gay 
                return outed 
            }
        }

        private mutating 
        func append<S>(components:some Sequence<S>) throws where S:StringProtocol 
        {
            for component:S in components
            {
                switch try ComponentSegmentation<String.Index>.init(parsing: component)
                {
                case .opaque(let hyphen): 
                    self.components.append(.init(String.init(component), hyphen: hyphen))
                    self.orientation = .straight 
                case .big:
                    self.components.append(.init(String.init(component)))
                    self.orientation = .straight 
                
                case .little                      (let start):
                    // an isolated little-component implies an empty big-predecessor, 
                    // and therefore resets the visibility counter
                    self.startIndex = self.components.endIndex
                    self.components.append(.init(String.init(component[start...])))
                    self.orientation = .gay 
                
                case .reveal(big: let end, little: let start):
                    self.components.append(.init(String.init(component[..<end])))
                    self.components.append(.init(String.init(component[start...])))
                    self.orientation = .gay 
                }
            }
        }
    }
    struct Disambiguator 
    {
        enum DocC 
        {
            case shape(Shape)
            case fnv(hash:UInt32)
        }

        var base:SymbolIdentifier?
        var host:SymbolIdentifier?
        var docC:DocC?

        init(base:SymbolIdentifier? = nil, host:SymbolIdentifier? = nil)
        {
            self.base = base 
            self.host = host 
            self.docC = nil
        }

        func disambiguate(_ selection:__owned Selection<Composite>, 
            context:some PackageContext) -> Selection<Composite>
        {
            guard case .many(let composites) = selection 
            else 
            {
                return selection
            }
            return .init(composites.filter { self.matches($0, context: context) }) ?? selection 
        }
        // in general, we cannot assume anything about the locality of the base or host 
        // components in a synthetic composite.
        func matches(_ composite:Composite, context:some PackageContext) -> Bool 
        {
            if  let host:Symbol = composite.host
            {
                if  let id:SymbolIdentifier = self.host, 
                    let host:Symbol.Intrinsic = context.load(host), 
                        host.id != id 
                {
                    return false 
                }
            }
            else 
            {
                guard case nil = self.host 
                else 
                {
                    return false 
                }
            }
            if  let id:SymbolIdentifier = self.base, 
                let base:Symbol.Intrinsic = context.load(composite.base)
            {
                return base.id == id 
            }
            else 
            {
                return true
            }
        }
    }
    struct Nationality 
    {
        let id:PackageIdentifier 
        let version:VersionSelector?
    }

    enum Orientation:Unicode.Scalar
    {
        case gay        = "."
        case straight   = "/"
    }

    private(set)
    var path:Path, 
        nationality:Nationality?,
        disambiguator:Disambiguator

    var startIndex:Path.Index
    {
        self.path.startIndex
    }
    var endIndex:Path.Index
    {
        self.path.endIndex
    }
    subscript(index:Path.Index) -> String
    {
        _read 
        {
            yield self.path[index].string
        }
    }
    
    private 
    init(path:Path, nationality:Nationality?, disambiguator:Disambiguator) 
    {
        self.path = path
        self.nationality = nationality
        self.disambiguator = disambiguator
    }
    init(path:Path) 
    {
        self.init(path: path, nationality: nil, disambiguator: .init())
    }

    var first:String
    {
        _read 
        {
            yield self.path.first.string
        }
    }
    var revealed:Self 
    {
        .init(path: self.path.revealed, 
            nationality: self.nationality,
            disambiguator: self.disambiguator)
    }
    var suffix:Self?
    {
        self.path.suffix.map 
        { 
            .init(path: $0, nationality: self.nationality, disambiguator: self.disambiguator) 
        }
    }
    var outed:Self?
    {
        self.path.outed.map 
        { 
            .init(path: $0, nationality: self.nationality, disambiguator: self.disambiguator) 
        }
    }

    /// Parses and removes the DocC suffix from the end of this symbollink. 
    /// 
    /// This operation may invalidate links to a package or an article. 
    /// Only call this if you are sure this symbollink is supposed to point 
    /// to a symbol.
    mutating 
    func disambiguate() 
    {
        if  let disambiguator:Disambiguator.DocC = 
                self.path.last.removeDocCFragment(global: self.path.count == 1)
        {
            self.disambiguator.docC = disambiguator
        }
    }
    func disambiguated() -> Self 
    {
        var link:Self = self 
            link.disambiguate() 
        return link
    }
}

extension _SymbolLink 
{
    init?(_ global:GlobalLink) throws 
    {
        guard let path:Path = try .init(components: global, fold: global.fold)
        else 
        {
            return nil 
        }
        self.init(path: path, 
            nationality: global.nationality, 
            disambiguator: .init(base: global.base, host: global.host))
    }
    init?(_ uri:URI) throws 
    {
        guard let path:Path = try .init(uri.path)
        else 
        {
            return nil 
        }
        self.init(path: path)
        if let query:[URI.Parameter] = uri.query 
        {
            self.update(with: query)
        }
    }
    mutating 
    func update(with parameters:some Sequence<URI.Parameter>)
    {
        for (key, value):(String, String) in parameters 
        {
            // slightly different from the parser in `PluralReference.swift`
            if  let key:GlobalLink.Parameter = .init(rawValue: key), 
                let id:SymbolIdentifier = try? .init(parsing: value.utf8)
            {
                switch key 
                {
                case .host: self.disambiguator.host = id
                case .base: self.disambiguator.base = id
                case .nationality: continue
                }
            }
        }
    }
}