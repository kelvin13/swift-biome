import PackageResolution
import Versions

public
enum Tag:Hashable, Sendable 
{
    case semantic(SemanticVersion.Masked)
    case named(String)

    init?(parsing string:some StringProtocol) 
    {
        if string.isEmpty 
        {
            return nil 
        }
        if let semantic:SemanticVersion.Masked = try? .init(parsing: string)
        {
            self = .semantic(semantic)
            return 
        }
        guard   string != ".",
                string != ".."
        else 
        {
            return nil
        }
        // a tag name must not contain a slash '/' (which is legal in git)
        for character:Character in string where character == "/"
        {
            return nil 
        }
        self = .named(String.init(string))
    }

    init?(_ requirement:PackageResolution.Requirement)
    {
        switch requirement 
        {
        case .version(let version): 
            self = .semantic(.init(version))
        case .branch(let name): 
            self.init(parsing: name)
        }
    }
}

extension Tag:CustomStringConvertible 
{
    public 
    var description:String
    {
        switch self 
        {
        case .semantic(let version):    return version.description
        case .named(let name):          return name
        }
    }
}