import JSON
import SymbolSource

extension Generic.Constraint<Int> 
{
    init(from json:JSON) throws 
    {
        let tuple:[JSON] = try json.as([JSON].self) { 3 ... 4 ~= $0 }
        self.init(
            try tuple.load(0),
            try tuple.load(1) { try $0.as(cases: Generic.ConstraintVerb.self) },
            try tuple.load(2),
            target: try tuple.count == 4 ? tuple.load(3, as: Int.self) : nil
        )
    }
    var serialized:JSON 
    {
        if let target:Int = self.target
        {
            return 
                [
                    .string(self.subject), 
                    .number(self.verb.rawValue), 
                    .string(self.object), 
                    .number(target),
                ]
        }
        else 
        {
            return 
                [
                    .string(self.subject), 
                    .number(self.verb.rawValue), 
                    .string(self.object), 
                ]
        }
    }
}