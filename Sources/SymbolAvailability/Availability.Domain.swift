extension Availability 
{
    @frozen public 
    struct DuplicateDomainError:CustomStringConvertible, Error 
    {
        public 
        let domain:Domain 

        init(_ domain:Domain)
        {
            self.domain = domain
        }

        public 
        var description:String 
        {
            "duplicate entries for availability domain '\(self.domain.rawValue)'"
        }
    }
    // https://github.com/apple/swift/blob/main/lib/SymbolGraphGen/AvailabilityMixin.cpp
    @frozen public 
    enum Domain:RawRepresentable
    {
        case general
        case swift
        case tools
        case platform(Platform)
        
        public 
        init?(rawValue:String)
        {
            switch rawValue 
            {
            case "*":       self = .general
            case "Swift":   self = .swift
            case "SwiftPM": self = .tools
            default: 
                guard let platform:Platform = .init(rawValue: rawValue)
                else 
                {
                    return nil 
                }
                self = .platform(platform)
            }
        }
        public 
        var rawValue:String 
        {
            switch self 
            {
            case .general:                  return "*"
            case .swift:                    return "Swift"
            case .tools:                    return "SwiftPM"
            case .platform(let platform):   return platform.rawValue
            }
        }
    }
}