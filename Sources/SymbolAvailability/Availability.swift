import Versions

@frozen public 
struct Availability:Equatable, Sendable
{
    public
    var swift:SwiftAvailability?
    //let tools:SwiftAvailability?
    public
    var general:UnversionedAvailability?
    public
    var platforms:[Platform: VersionedAvailability]
    
    @inlinable public
    var isEmpty:Bool 
    {
        if  case nil = self.swift, 
            case nil = self.general, 
            self.platforms.isEmpty 
        {
            return true 
        }
        else 
        {
            return false
        }
    }
    @inlinable public
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
    @inlinable public
    init(swift:SwiftAvailability? = nil, 
        general:UnversionedAvailability? = nil, 
        platforms:[Platform: VersionedAvailability] = [:])
    {
        self.swift = swift
        self.general = general
        self.platforms = platforms
    }
}
extension Availability 
{
    public 
    init(_ items:[(key:Domain, value:VersionedAvailability)]) throws
    {
        self.init()
        for (key, value):(Domain, VersionedAvailability) in items
        {
            switch key 
            {
            case .general:
                if case nil = self.general
                {
                    self.general = .init(value)
                }
                else 
                {
                    throw DuplicateDomainError.init(key)
                }
            
            case .swift:
                if case nil = self.swift 
                {
                    self.swift = .init(value)
                }
                else 
                {
                    throw DuplicateDomainError.init(key)
                }
            
            case .tools:
                fatalError("unimplemented (yet)")
            
            case .platform(let platform):
                guard case nil = self.platforms.updateValue(value, forKey: platform)
                else 
                {
                    throw DuplicateDomainError.init(key)
                }
            }
        }
    }
}
