import Grammar

extension Sequence where Element == URI.Vector?
{
    @inlinable public
    var normalized:(components:[String], fold:Int)
    {
        // ii. lexical normalization 
        //
        // ['', 'foo', 'bar', < nil >, 'bax.qux', < Self >, '', 'baz.bar', '.Foo', '..', '', ''] becomes 
        // [    'foo', 'bar',                                   'baz.bar', '.Foo', '..']
        //                                                      ^~~~~~~~~~~~~~~~~~~~~~~
        //                                                      (visible = 3)
        //  if `Self` components would erase past the beginning of the components list, 
        //  the extra `Self` components are ignored.
        //  redirects generated from this step are PERMANENT. 
        //  paths containing `nil` and empty components always generate redirects.
        //  however, the presence and location of an empty component can be meaningful 
        //  in a symbollink.    
        var components:[String] = []
            components.reserveCapacity(self.underestimatedCount)
        var fold:Int = components.endIndex
        for vector:URI.Vector? in self
        {
            switch vector 
            {
            case .pop?:
                let _:String? = components.popLast()
                fallthrough
            case nil: 
                fold = components.endIndex
            case .push(let component): 
                components.append(component)
            }
        }
        return (components, fold)
    }
}
extension RangeReplaceableCollection where Element == URI.Vector? 
{
    @inlinable public mutating 
    func append(component:String)
    {
        self.append(component.isEmpty ? nil : .push(component))
    }
    @inlinable public mutating 
    func append<Components>(components:Components) 
        where Components:Sequence, Components.Element == String
    {
        self.reserveCapacity(self.underestimatedCount + components.underestimatedCount)
        for component:String in components 
        {
            self.append(component: component)
        }
    }
}

@frozen public 
struct URI:CustomStringConvertible, Sendable
{
    @frozen public 
    enum Vector:Hashable, Sendable
    {
        /// '..'
        case pop 
        /// A regular path component. This can be '.' or '..' if at least one 
        /// of the dots was percent-encoded.
        case push(String)
    }
    public 
    typealias Parameter = (key:String, value:String)
    
    public 
    var path:[Vector?]
    public 
    var query:[Parameter]?
    
    @inlinable public 
    var description:String 
    {
        var string:String = self.path.isEmpty ? "/" : ""
        for vector:Vector? in self.path
        {
            switch vector
            {
            case  nil: 
                string += "/."
            case .pop?: 
                string += "/.."
            case .push(let component)?: 
                string += "/\(Self.encode(utf8: component.utf8))"
            }
        }
        guard let parameters:[Parameter] = self.query 
        else 
        {
            return string
        }
        // don’t bother percent-encoding the query parameters
        string.append("?")
        string += parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return string
    }
    
    @inlinable public static 
    func ~= (lhs:Self, rhs:Self) -> Bool 
    {
        guard lhs.path == rhs.path 
        else 
        {
            return false 
        }
        switch (lhs.query, rhs.query)
        {
        case (_?, nil), (nil, _?): 
            return false
        case (nil, nil):
            return true 
        case (let lhs?, let rhs?):
            guard lhs.count == rhs.count 
            else 
            {
                return false 
            }
            var unmatched:[String: String] = .init(minimumCapacity: lhs.count)
            for (key, value):(String, String) in lhs 
            {
                guard case nil = unmatched.updateValue(value, forKey: key)
                else
                {
                    return false
                }
            }
            for (key, value):(String, String) in rhs
            {
                guard case value? = unmatched.removeValue(forKey: key)
                else
                {
                    return false
                }
            }
            return true
        }
    }
    
    @inlinable public
    init(root:String, query:[Parameter]? = nil)
    {
        self.init(path: CollectionOfOne<String>.init(root), query: query)
    }
    @inlinable public
    init(path:[Vector?] = [], query:[Parameter]?)
    {
        self.path = path == [nil] ? [] : path
        self.query = query
    }
    @inlinable public
    init<Path>(path:Path, query:[Parameter]? = nil)
        where Path:Sequence, Path.Element == String
    {
        self.init(query: query)
        self.path.append(components: path)
    }
    @inlinable public
    init(absolute string:some StringProtocol) throws 
    {
        self = try Absolute<String.Index>.parse(string.utf8)
    }
    @inlinable public
    init(relative string:some StringProtocol) throws 
    {
        self = try Relative<String.Index>.parse(string.utf8)
    }
    
    @inlinable public static 
    func encode<UTF8>(utf8 bytes:UTF8) -> String
        where UTF8:Sequence, UTF8.Element == UInt8
    {
        var utf8:[UInt8] = []
            utf8.reserveCapacity(bytes.underestimatedCount)
        for byte:UInt8 in bytes
        {
            if let byte:UInt8 = Self.filter(byte: byte)
            {
                utf8.append(byte)
            }
            else 
            {
                // percent-encode
                utf8.append(0x25) // '%'
                utf8.append(Self.hex(uppercasing: byte >> 4))
                utf8.append(Self.hex(uppercasing: byte & 0x0f))
            }
        }
        return .init(unsafeUninitializedCapacity: utf8.count) 
        { 
            $0.initialize(from: utf8).1 - $0.startIndex
        }
    }
    @inlinable public static 
    func filter(byte:UInt8) -> UInt8?
    {
        switch byte 
        {
        case    0x30 ... 0x39,  // [0-9]
                0x41 ... 0x5a,  // [A-Z]
                0x61 ... 0x7a,  // [a-z]
                0x2d,           // '-'
                0x2e,           // '.'
                // not technically a URL character, but browsers won’t render '%3A' 
                // in the URL bar, and ':' is so common in Swift it is not worth 
                // percent-encoding. 
                // the ':' character also appears in legacy USRs.
                0x3a,           // ':' 
                0x5f,           // '_'
                0x7e:           // '~'
            return byte 
        default: 
            return nil 
        }
    }
    @inlinable public static 
    func hex(uppercasing value:UInt8) -> UInt8
    {
        (value < 10 ? 0x30 : 0x37) + value 
    }
}

extension URI 
{
    @inlinable public 
    func appending(component:String) -> Self 
    {
        self.appending(components: CollectionOfOne<String>.init(component))
    }
    @inlinable public 
    func appending<Components>(components:Components) -> Self 
        where Components:Sequence, Components.Element == String
    {
        var uri:Self = self
            uri.path.append(components: components)
        return uri
    }
    @inlinable public mutating 
    func insert(parameter:Parameter) 
    {
        switch self.query 
        {
        case nil:
            self.query = [parameter]
        case var parameters?:
            self.query = nil 
            parameters.append(parameter)
            self.query = parameters
        }
    }
}

extension URI:ExpressibleByArrayLiteral 
{
    @inlinable public 
    init(arrayLiteral:String...)
    {
        self.init(path: arrayLiteral)
    }
}
