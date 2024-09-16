import Versions 

@frozen public 
struct SwiftAvailability:Equatable, Sendable
{
    // unconditionals not allowed 
    public 
    var deprecated:SemanticVersion.Masked?
    public 
    var introduced:SemanticVersion.Masked?
    public 
    var obsoleted:SemanticVersion.Masked?
    public 
    var renamed:String?
    public 
    var message:String?
    
    @inlinable public
    init(deprecated:SemanticVersion.Masked?,
        introduced:SemanticVersion.Masked?,
        obsoleted:SemanticVersion.Masked?,
        renamed:String?,
        message:String?)
    {
        self.deprecated = deprecated
        self.introduced = introduced
        self.obsoleted = obsoleted
        self.renamed = renamed
        self.message = message
    }
    
    init(_ versioned:VersionedAvailability)
    {
        if case .since(let deprecated) = versioned.deprecated 
        {
            self.deprecated = deprecated
        }
        else 
        {
            self.deprecated = nil
        }
        self.introduced = versioned.introduced
        self.obsoleted = versioned.obsoleted
        self.renamed = versioned.renamed
        self.message = versioned.message
    }

    @inlinable public 
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
}