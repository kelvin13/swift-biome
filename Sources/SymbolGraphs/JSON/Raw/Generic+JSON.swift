import JSON
import SymbolSource

extension Generic 
{
    init(lowering json:JSON) throws 
    {
        self = try json.lint 
        {
            .init(
                name:  try $0.remove("name", as: String.self),
                index: try $0.remove("index", as: Int.self),
                depth: try $0.remove("depth", as: Int.self)
            )
        }
    }
}
