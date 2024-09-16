import HTML
import SymbolAvailability
import Versions

extension [Platform: VersionedAvailability]
{
    var html:HTML.Element<Never>?
    {
        var items:[HTML.Element<Never>] = []
        for platform:Platform in Platform.allCases
        {
            guard let availability:VersionedAvailability = self[platform]
            else 
            {
                continue 
            }
            if availability.unavailable 
            {
                items.append(.li("\(platform.rawValue) unavailable"))
            }
            else if let deprecated:VersionedAvailability.Deprecation = availability.deprecated 
            {
                switch deprecated 
                {
                case .always:
                    items.append(.li("\(platform.rawValue) deprecated"))
                case .since(let version):
                    items.append(.li("\(platform.rawValue) deprecated since \(version.description)"))
                }
            }
            else if let version:SemanticVersion.Masked = availability.introduced 
            {
                items.append(.li("\(platform.rawValue) \(version.description)+"))
            }
        }
        return items.isEmpty ? nil : .section(.ul(items), attributes: [.class("platforms")])
    }
}