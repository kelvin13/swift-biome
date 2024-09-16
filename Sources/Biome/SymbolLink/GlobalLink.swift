import SymbolSource
import URI

struct GlobalLink:RandomAccessCollection 
{
    enum Parameter:String 
    {
        case base           = "overload"
        case host           = "self"
        case nationality    = "from"
    }

    var nationality:_SymbolLink.Nationality?
    var base:SymbolIdentifier?
    var host:SymbolIdentifier?

    private 
    let components:[String]
    private(set)
    var startIndex:Int 
    let fold:Int 
    var endIndex:Int 
    {
        self.components.endIndex
    }
    subscript(index:Int) -> String
    {
        _read 
        {
            yield self.components[index]
        }
    }

    init(_ uri:URI)  
    {
        self.init(uri.path)
        if let query:[URI.Parameter] = uri.query 
        {
            self.update(with: query)
        }
    }
    
    init(_ vectors:some Sequence<URI.Vector?>)  
    {
        (self.components, self.fold) = vectors.normalized
        self.startIndex = self.components.startIndex
        self.nationality = nil 
        self.base = nil 
        self.host = nil 
    }

    mutating 
    func update(with parameters:some Sequence<URI.Parameter>)
    {
        for (key, value):(String, String) in parameters 
        {
            switch Parameter.init(rawValue: key)
            {
            case nil: 
                continue 
            
            case .nationality?:
                // either 'from=swift-foo' or 'from=swift-foo/0.1.2'. 
                // we do not tolerate missing slashes
                var separator:String.Index = value.firstIndex(of: "/") ?? value.endIndex
                let id:PackageIdentifier = .init(value[..<separator])

                while separator < value.endIndex, value[separator] != "/"
                {
                    value.formIndex(after: &separator)
                }
                self.nationality = .init(id: id, version: .init(parsing: value[separator...]))
            
            case .host?:
                // if the mangled name contained a colon ('SymbolGraphGen style'), 
                // the parsing rule will remove it.
                if  let host:SymbolIdentifier = try? .init(parsing: value.utf8)
                {
                    self.host = host
                }
            
            case .base?: 
                switch try? USR.init(parsing: value.utf8) 
                {
                case nil: 
                    continue 
                
                case .natural(let base)?:
                    self.base = base
                
                case .synthesized(from: let base, for: let host)?:
                    // this is supported for backwards-compatibility, 
                    // but the `::SYNTHESIZED::` infix is deprecated, 
                    // so this will end up causing a redirect 
                    self.host = host
                    self.base = base 
                }
            }
        }
    }

    mutating 
    func descend() -> String?
    {
        if let first:String = self.first 
        {
            self.startIndex += 1 
            return first
        }
        else 
        {
            return nil 
        }
    }
    mutating 
    func descend<T>(where transform:(String) throws -> T?) rethrows -> T? 
    {
        if  let first:String = self.first, 
            let transformed:T = try transform(first)
        {
            self.startIndex += 1 
            return transformed
        }
        else 
        {
            return nil 
        }
    }
}