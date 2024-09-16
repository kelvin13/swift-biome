import JSON
import SymbolSource

extension Generic 
{
    init(from json:JSON) throws 
    {
        let tuple:[JSON] = try json.as([JSON].self, count: 3)
        self.init(name: try tuple.load(0),
            index: try tuple.load(1),
            depth: try tuple.load(2))
    }
    var serialized:JSON 
    {
        [
            .string(self.name),
            .number(self.index),
            .number(self.depth)
        ]
    }
}

