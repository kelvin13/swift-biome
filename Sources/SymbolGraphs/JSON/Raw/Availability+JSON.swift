import JSON
import SymbolAvailability
import Versions

extension Availability
{
    init(lowering json:[JSON]) throws 
    {
        try self.init(try json.map 
        {
            try $0.lint
            {
                let deprecated:VersionedAvailability.Deprecation? 
                if let flag:Bool = try $0.pop("isUnconditionallyDeprecated", as: Bool.self)
                {
                    deprecated = flag ? .always : nil
                }
                else if let version:SemanticVersion.Masked? = 
                    try $0.pop("deprecated", SemanticVersion.Masked.init(exactly:))
                {
                    deprecated = version.map(VersionedAvailability.Deprecation.since(_:))
                }
                else 
                {
                    deprecated = nil 
                }
                // possible to be both unconditionally unavailable and unconditionally deprecated
                let availability:VersionedAvailability = .init(
                    unavailable: try $0.pop("isUnconditionallyUnavailable", as: Bool.self) ?? false,
                    deprecated: deprecated,
                    introduced: try $0.pop("introduced", SemanticVersion.Masked.init(exactly:)) ?? nil,
                    obsoleted: try $0.pop("obsoleted", SemanticVersion.Masked.init(exactly:)) ?? nil, 
                    renamed: try $0.pop("renamed", as: String?.self),
                    message: try $0.pop("message", as: String?.self))
                let domain:Domain = try $0.remove("domain") { try $0.as(cases: Domain.self) }
                return (key: domain, value: availability)
            }
        })
    }
}