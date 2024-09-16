import JSON
import SymbolSource 

extension Path 
{
    init(from json:JSON) throws
    {
        let components:[JSON] = try json.as([JSON].self) { $0 > 0 }
        let last:Int = components.index(before: components.endIndex)
        self.init(
            prefix: try components[..<last].map { try $0.as(String.self) }, 
            last: try components.load(last, as: String.self))
    }
}
