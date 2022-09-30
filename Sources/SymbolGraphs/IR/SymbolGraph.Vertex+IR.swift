import JSON
import Notebook
import SymbolAvailability
import SymbolSource

extension IR 
{
    enum Vertex 
    {
        static let path:String = "p"
        static let origin:String = "o"
        static let comment:String = "d"
    }
    enum Declaration 
    {
        static let fragments:String = "f"
        static let signature:String = "s"
        static let availability:String = "a"
        static let extensionConstraints:String = "e"
        static let genericConstraints:String = "c"
        static let generics:String = "g"
    }
}
extension SymbolGraph.Vertex<Int> 
{
    init(from json:JSON, shape:Shape) throws 
    {
        self = try json.lint 
        {
            .init(path: try $0.remove(IR.Vertex.path, Path.init(from:)) as Path,
                shape: shape,
                declaration: .init(
                    fragments: try $0.remove(IR.Declaration.fragments, 
                        Notebook<Highlight, Int>.init(from:)),  
                    signature: try $0.remove(IR.Declaration.signature, 
                        Notebook<Highlight, Never>.init(from:)),
                    availability: 
                        try $0.pop(IR.Declaration.availability, Availability.init(from:)) ?? .init(),
                    extensionConstraints: 
                        try $0.pop(IR.Declaration.extensionConstraints, as: [JSON].self)
                    {
                        try $0.map(Generic.Constraint<Int>.init(from:)) 
                    } ?? [],
                    genericConstraints: 
                        try $0.pop(IR.Declaration.genericConstraints, as: [JSON].self)
                    {
                        try $0.map(Generic.Constraint<Int>.init(from:)) 
                    } ?? [], 
                    generics: try $0.pop(IR.Declaration.generics, as: [JSON].self) 
                    {
                        try $0.map(Generic.init(from:))
                    } ?? []),
                comment: .init(try $0.pop(IR.Vertex.comment, as: String.self), 
                    extends: try $0.pop(IR.Vertex.origin, as: Int.self))) 
        }
    }
    var serialized:JSON 
    {
        var items:[(key:String, value:JSON)] =
        [
            (IR.Vertex.path, .array(self.path.map(JSON.string(_:)))),
            (IR.Declaration.fragments, .array(self.declaration.fragments.map(\.serialized))),
            (IR.Declaration.signature, .array(self.declaration.signature.map(\.serialized))),
        ]
        if !self.declaration.availability.isEmpty
        {
            items.append((IR.Declaration.availability, 
                self.declaration.availability.serialized))
        }
        if !self.declaration.extensionConstraints.isEmpty
        {
            items.append((IR.Declaration.extensionConstraints, 
                .array(self.declaration.extensionConstraints.map(\.serialized))))
        }
        if !self.declaration.genericConstraints.isEmpty
        {
            items.append((IR.Declaration.genericConstraints, 
                .array(self.declaration.genericConstraints.map(\.serialized))))
        }
        if !self.declaration.generics.isEmpty
        {
            items.append((IR.Declaration.generics, 
                .array(self.declaration.generics.map(\.serialized))))
        }
        if let comment:String = self.comment.string 
        {
            items.append((IR.Vertex.comment, .string(comment)))
        }
        if let origin:Int = self.comment.extends 
        {
            items.append((IR.Vertex.origin, .number(origin)))
        }
        return .object(items)
    }
}
