@frozen public 
struct UnversionedAvailability:Equatable, Sendable
{
    public 
    var unavailable:Bool 
    public 
    var deprecated:Bool 
    public 
    var renamed:String?
    public 
    var message:String?

    @inlinable public
    init(unavailable:Bool,
        deprecated:Bool, 
        renamed:String?,
        message:String?)
    {
        self.unavailable = unavailable
        self.deprecated = deprecated
        self.renamed = renamed
        self.message = message
    }
    
    init(_ versioned:VersionedAvailability)
    {
        self.unavailable = versioned.unavailable 
        self.deprecated = versioned.isGenerallyDeprecated 
        self.renamed = versioned.renamed 
        self.message = versioned.message
    }
}