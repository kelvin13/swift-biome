import JSON
import Notebook
import SymbolAvailability
import SymbolSource

extension SymbolGraph.Vertex<Int> 
{
    private
    enum CodingKeys 
    {
        static let path:String = "p"
        static let origin:String = "o"
        static let comment:String = "d"

        static let fragments:String = "f"
        static let signature:String = "s"
        static let availability:String = "a"
        static let extensionConstraints:String = "e"
        static let genericConstraints:String = "c"
        static let generics:String = "g"
    }
    init(from json:JSON, shape:Shape) throws 
    {
        self = try json.lint 
        {
            .init(intrinsic: .init(shape: shape,
                    path: try $0.remove(CodingKeys.path, Path.init(from:)) as Path),
                declaration: .init(
                    fragments: try $0.remove(CodingKeys.fragments, 
                        Notebook<Highlight, Int>.init(from:)),  
                    signature: try $0.remove(CodingKeys.signature, 
                        Notebook<Highlight, Never>.init(from:)),
                    availability: 
                        try $0.pop(CodingKeys.availability, Availability.init(from:)) ?? .init(),
                    extensionConstraints: 
                        try $0.pop(CodingKeys.extensionConstraints, as: [JSON].self)
                    {
                        try $0.map(Generic.Constraint<Int>.init(from:)) 
                    } ?? [],
                    genericConstraints: 
                        try $0.pop(CodingKeys.genericConstraints, as: [JSON].self)
                    {
                        try $0.map(Generic.Constraint<Int>.init(from:)) 
                    } ?? [], 
                    generics: try $0.pop(CodingKeys.generics, as: [JSON].self) 
                    {
                        try $0.map(Generic.init(from:))
                    } ?? []),
                comment: .init(try $0.pop(CodingKeys.comment, as: String.self), 
                    extends: try $0.pop(CodingKeys.origin, as: Int.self))) 
        }
    }
    var serialized:JSON 
    {
        var items:[(key:String, value:JSON)] =
        [
            (CodingKeys.path, .array(self.path.map(JSON.string(_:)))),
            (CodingKeys.fragments, .array(self.declaration.fragments.map(\.serialized))),
            (CodingKeys.signature, .array(self.declaration.signature.map(\.serialized))),
        ]
        if !self.declaration.availability.isEmpty
        {
            items.append((CodingKeys.availability, 
                self.declaration.availability.serialized))
        }
        if !self.declaration.extensionConstraints.isEmpty
        {
            items.append((CodingKeys.extensionConstraints, 
                .array(self.declaration.extensionConstraints.map(\.serialized))))
        }
        if !self.declaration.genericConstraints.isEmpty
        {
            items.append((CodingKeys.genericConstraints, 
                .array(self.declaration.genericConstraints.map(\.serialized))))
        }
        if !self.declaration.generics.isEmpty
        {
            items.append((CodingKeys.generics, 
                .array(self.declaration.generics.map(\.serialized))))
        }
        if let comment:String = self.comment.string 
        {
            items.append((CodingKeys.comment, .string(comment)))
        }
        if let origin:Int = self.comment.extends 
        {
            items.append((CodingKeys.origin, .number(origin)))
        }
        return .object(items)
    }
}
