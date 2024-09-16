import JSON
import Notebook
import SymbolSource

extension Notebook<Highlight, Never>
{
    init(from json:JSON) throws 
    {
        self.init(try json.as([JSON].self).lazy.map 
        {
            let tuple:[JSON] = try $0.as([JSON].self, count: 2)
            let text:String = try tuple.load(0)
            let color:Highlight = try tuple.load(1) { try $0.as(cases: Highlight.self) }
            return (text, color)
        })
    }
}
extension Notebook<Highlight, Int>
{
    init(from json:JSON) throws 
    {
        self.init(try json.as([JSON].self).lazy.map(Fragment.init(from:)))
    }
}

extension Notebook<Highlight, Int>.Fragment
{
    init(from json:JSON) throws 
    {
        let tuple:[JSON] = try json.as([JSON].self) { 2 ... 3 ~= $0 }
        self.init( try tuple.load(0),
            color: try tuple.load(1) { try $0.as(cases: Highlight.self) },
            link: try tuple.count == 3 ? tuple.load(2) : nil)
    }
    var serialized:JSON 
    {
        if let link:Int = self.link
        {
            return [.string(self.text), .number(self.color.rawValue), .number(link)]
        }
        else 
        {
            return [.string(self.text), .number(self.color.rawValue)]
        }
    }
}
extension Notebook<Highlight, Never>.Fragment
{
    var serialized:JSON 
    {
        [.string(self.text), .number(self.color.rawValue)]
    }
}