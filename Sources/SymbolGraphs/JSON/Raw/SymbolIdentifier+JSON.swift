import JSON
import SymbolSource

extension SymbolIdentifier
{
    init(from json:JSON) throws 
    {
        try self.init(parsing: try json.as(String.self).utf8)
    }
}
