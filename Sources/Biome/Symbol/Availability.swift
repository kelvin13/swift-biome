public 
enum Platform:String, CaseIterable, Hashable, Sendable 
{
    case iOS 
    case macOS
    case macCatalyst
    case tvOS
    case watchOS
    case windows    = "Windows"
    case openBSD    = "OpenBSD"
    
    case iOSApplicationExtension
    case macOSApplicationExtension
    case macCatalystApplicationExtension
    case tvOSApplicationExtension
    case watchOSApplicationExtension
}
public 
struct Availability:Equatable, Sendable
{
    // https://github.com/apple/swift/blob/main/lib/SymbolGraphGen/AvailabilityMixin.cpp
    public 
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
    
    var swift:SwiftAvailability?
    //let tools:SwiftAvailability?
    var general:UnversionedAvailability?
    var platforms:[Platform: VersionedAvailability]
    
    var isUsable:Bool 
    {
        if  let generally:UnversionedAvailability = self.general, 
                generally.unavailable || generally.deprecated
        {
            return false 
        }
        if  let currently:SwiftAvailability = self.swift, 
               !currently.isUsable
        {
            return false 
        }
        else 
        {
            return true
        }
    }
    
    init()
    {
        self.swift = nil 
        self.general = nil 
        self.platforms = [:]
    }
}
struct SwiftAvailability:Equatable, Sendable
{
    // unconditionals not allowed 
    var deprecated:MaskedVersion?
    var introduced:MaskedVersion?
    var obsoleted:MaskedVersion?
    var renamed:String?
    var message:String?
    
    var isUsable:Bool 
    {
        if case _? = self.deprecated
        {
            return false 
        }
        if case _? = self.obsoleted 
        {
            return false 
        }
        else 
        {
            return true
        }
    }
    
    init(_ versioned:VersionedAvailability)
    {
        self.deprecated = versioned.deprecated ?? nil
        self.introduced = versioned.introduced
        self.obsoleted = versioned.obsoleted
        self.renamed = versioned.renamed
        self.message = versioned.message
    }
}
struct UnversionedAvailability:Equatable, Sendable
{
    var unavailable:Bool 
    var deprecated:Bool 
    var renamed:String?
    var message:String?
    
    init(_ versioned:VersionedAvailability)
    {
        self.unavailable = versioned.unavailable 
        self.deprecated = versioned.isGenerallyDeprecated 
        self.renamed = versioned.renamed 
        self.message = versioned.message
    }
}
struct VersionedAvailability:Equatable, Sendable 
{
    var unavailable:Bool 
    // .some(nil) represents unconditional deprecation
    var deprecated:MaskedVersion??
    var introduced:MaskedVersion?
    var obsoleted:MaskedVersion?
    var renamed:String?
    var message:String?
    
    var isGenerallyDeprecated:Bool 
    {
        if case .some(nil) = self.deprecated 
        {
            return true 
        }
        else 
        {
            return false 
        }
    }
}