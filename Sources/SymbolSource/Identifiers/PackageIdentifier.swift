@frozen public 
enum PackageIdentifier:Hashable, Comparable, Sendable
{
    case swift 
    case core
    case community(normalized:String)
}
extension PackageIdentifier:ExpressibleByStringLiteral 
{
    @inlinable public 
    init(stringLiteral:String)
    {
        self.init(stringLiteral)
    }
    @inlinable public
    init(_ string:some StringProtocol)
    {
        switch string.lowercased() 
        {
        case    "swift-standard-library",
                "standard-library",
                "swift-stdlib",
                "stdlib":
            self = .swift
        case    "swift-core-libraries", 
                "corelibs":
            self = .core
        case let name:
            self = .community(normalized: name)
        }
    }
}
extension PackageIdentifier:LosslessStringConvertible 
{
    @inlinable public 
    var string:String 
    {
        switch self
        {
        case .swift:                return "swift-standard-library"
        case .core:                 return "swift-core-libraries"
        case .community(let name):  return name 
        }
    }
    @inlinable public 
    var description:String 
    {
        self.string
    }
}
extension PackageIdentifier:Decodable 
{
    @inlinable public 
    init(from decoder:any Decoder) throws 
    {
        self.init(try decoder.singleValueContainer().decode(String.self))
    }
}