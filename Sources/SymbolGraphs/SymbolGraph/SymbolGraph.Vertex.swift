import JSON
import Notebook
import SymbolSource

extension SymbolGraph.Vertex:Sendable where Target:Sendable {}
extension SymbolGraph.Vertex:Equatable where Target:Equatable {}

extension SymbolGraph.Comment:Sendable where Target:Sendable {}
extension SymbolGraph.Comment:Equatable where Target:Equatable {}

extension SymbolGraph 
{
    @frozen public
    struct Intrinsic:Equatable, Sendable
    {
        public 
        let path:Path
        public
        let shape:Shape

        init(shape:Shape, path:Path)
        {
            self.path = path
            self.shape = shape
        }
    }
    @frozen public
    struct Comment<Target>
    {
        public
        var string:String?
        public
        var extends:Target?

        @inlinable public 
        init(string:String?, extends:Target?)
        {
            self.string = string 
            self.extends = extends
        }
        @inlinable public 
        init(_ string:String? = nil, extends:Target? = nil)
        {
            self.init(string: string.flatMap { $0.isEmpty ? nil : $0 }, extends: extends)
        }
        @inlinable public 
        func map<T>(_ transform:(Target) throws -> T) rethrows -> Comment<T>
        {
            .init(string: self.string, extends: try self.extends.map(transform))
        }
        @inlinable public 
        func forEachTarget(_ body:(Target) throws -> ()) rethrows 
        {
            try self.extends.map(body)
        }
    }

    @frozen public
    struct Vertex<Target>
    {
        public
        let intrinsic:Intrinsic
        public 
        let declaration:Declaration<Target>
        public 
        var comment:Comment<Target>

        @inlinable public 
        init(intrinsic:Intrinsic,
            declaration:Declaration<Target>,
            comment:Comment<Target> = .init())
        {
            self.intrinsic = intrinsic
            self.declaration = declaration
            self.comment = comment
        }

        @inlinable public 
        func map<T>(_ transform:(Target) throws -> T) rethrows -> Vertex<T>
        {
            .init(intrinsic: self.intrinsic, 
                declaration: try self.declaration.map(transform), 
                comment: try self.comment.map(transform))
        }
        func forEachTarget(_ body:(Target) throws -> ()) rethrows 
        {
            try self.declaration.forEachTarget(body)
            try self.comment.forEachTarget(body)
        }

        var shape:Shape
        {
            self.intrinsic.shape
        }
        var path:Path
        {
            self.intrinsic.path
        }
    }
}
extension SymbolGraph.Vertex 
{
    static 
    func `protocol`(_ path:Path) -> Self 
    {
        let fragments:[Notebook<Highlight, Target>.Fragment] = 
        [
            .init("protocol",   color: .keywordText),
            .init(" ",          color: .text),
            .init(path.last,    color: .identifier),
        ]
        return .init(intrinsic: .init(shape: .protocol, path: path),
            declaration: .init(
                fragments: .init(fragments), 
                signature: .init(fragments)))
    }
}
