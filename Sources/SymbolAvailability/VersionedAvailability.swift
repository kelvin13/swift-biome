import Versions 

@frozen public 
struct VersionedAvailability:Equatable, Sendable 
{
    @frozen public 
    enum Deprecation:Hashable, Sendable
    {
        case always
        case since(SemanticVersion.Masked)
    }
    public 
    var unavailable:Bool 
    // .some(nil) represents unconditional deprecation
    public 
    var deprecated:Deprecation?
    public 
    var introduced:SemanticVersion.Masked?
    public 
    var obsoleted:SemanticVersion.Masked?
    public 
    var renamed:String?
    public 
    var message:String?

    @inlinable public
    init(unavailable:Bool,
        deprecated:Deprecation?,
        introduced:SemanticVersion.Masked?,
        obsoleted:SemanticVersion.Masked?,
        renamed:String?,
        message:String?)
    {
        self.unavailable = unavailable
        self.deprecated = deprecated
        self.introduced = introduced
        self.obsoleted = obsoleted
        self.renamed = renamed
        self.message = message
    }
    
    @inlinable public 
    var isGenerallyDeprecated:Bool 
    {
        if case .always? = self.deprecated 
        {
            return true 
        }
        else 
        {
            return false 
        }
    }
}
