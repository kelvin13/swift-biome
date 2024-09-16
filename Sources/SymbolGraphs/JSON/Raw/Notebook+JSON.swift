import JSON 
import Notebook
import SymbolSource

extension Notebook<Highlight, Never>
{
    init(lowering json:JSON) throws 
    {
        self.init(try json.as([JSON].self).lazy.map 
        {
            try $0.lint(whitelisting: ["preciseIdentifier"]) 
            {
                let text:String = try $0.remove("spelling", as: String.self)
                return (text, try $0.remove("kind") { try Highlight.init(from: $0, text: text) })
            }
        })
    }
}
extension Notebook<Highlight, SymbolIdentifier>
{
    init(lowering json:JSON) throws 
    {
        self.init(try json.as([JSON].self).lazy.map(Fragment.init(lowering:)))
    }
}
extension Notebook<Highlight, SymbolIdentifier>.Fragment
{
    init(lowering json:JSON) throws 
    {
        self = try json.lint 
        {
            let text:String = try $0.remove("spelling", as: String.self)
            return .init(text, 
                color: try $0.remove("kind") { try Highlight.init(from: $0, text: text) }, 
                link: try $0.pop("preciseIdentifier", SymbolIdentifier.init(from:)))
        }
    }
}
