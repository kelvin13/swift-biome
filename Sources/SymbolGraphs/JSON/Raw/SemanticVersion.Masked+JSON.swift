import Versions 
import JSON

extension SemanticVersion.Masked
{
    init?(exactly json:JSON) throws 
    {
        do 
        {
            try self.init(from: json)
        }
        catch let error as JSON.RecursiveError
        {
            guard error.next is JSON.IntegerOverflowError 
            else 
            {
                throw error
            }
            return nil
        }
    }
    init(from json:JSON) throws 
    {
        self = try json.lint 
        {
            let major:UInt16 = try $0.remove("major", as: UInt16.self)
            guard let minor:UInt16 = try $0.pop("minor", as: UInt16.self)
            else 
            {
                return .major(major)
            }
            guard let patch:UInt16 = try $0.pop("patch", as: UInt16.self)
            else 
            {
                return .minor(major, minor)
            }
            return .patch(major, minor, patch)
        }
    }
}
