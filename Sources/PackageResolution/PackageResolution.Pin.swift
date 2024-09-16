import JSON
import SymbolSource
import Versions

extension PackageResolution
{
    public 
    enum Requirement:Sendable
    {
        case version(SemanticVersion)
        case branch(String)
    }
    
    public 
    struct Pin:Identifiable, Sendable 
    {
        public 
        let id:PackageIdentifier
        public 
        let location:String?
        public 
        let revision:String
        public
        let requirement:Requirement 

        public 
        init(id:PackageIdentifier, location:String? = nil, 
            revision:String, 
            requirement:Requirement)
        {
            self.id = id 
            self.location = location 
            self.revision = revision 
            self.requirement = requirement
        }
        
        public 
        init(from json:JSON) throws 
        {
            (self.id, self.location, self.revision, self.requirement) = 
                try json.lint(whitelisting: ["kind"])
            {
                let id:ID = .init(
                    try $0.pop("identity", as: String.self) ?? 
                        $0.remove("package", as: String.self))
                let location:String? = try $0.pop("location", as: String.self) ?? 
                    $0.pop("repositoryURL", as: String.self)
                let (revision, requirement):(String, Requirement) = try $0.remove("state")
                {
                    try $0.lint(whitelisting: ["branch"]) 
                    {
                        let revision:String = try $0.remove("revision", as: String.self)
                        let requirement:Requirement
                        if let version:String = try $0.pop("version", as: String?.self)
                        {
                            requirement = .version(try .init(parsing: version))
                        }
                        else 
                        {
                            requirement = .branch(try $0.remove("branch", as: String.self))
                        }
                        return (revision, requirement)
                    }
                }
                return (id, location, revision, requirement)
            }
        }
    }
}
