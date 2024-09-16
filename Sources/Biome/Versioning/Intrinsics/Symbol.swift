import SymbolGraphs
import SymbolSource

extension Symbol:IntrinsicReference
{
    struct Intrinsic:Identifiable, Sendable
    {
        let id:SymbolIdentifier
        //  TODO: see if small-array optimizations here are beneficial, since this could 
        //  often be a single-element array
        let path:Path
        let kind:Kind
        let route:Route
        var scope:Scope?

        init(id:SymbolIdentifier, path:Path, kind:Kind, route:Route)
        {
            self.id = id 
            self.path = path
            self.kind = kind
            self.route = route
            self.scope = nil
        }
    }
}

extension Symbol.Intrinsic
{
    struct Display 
    {
        let path:Path
        let shape:Shape

        var name:String 
        {
            self.path.last
        }
    }
    
    var shape:Shape
    {
        self.kind.shape 
    } 
    var name:String 
    {
        self.path.last
    }
    //  this is only the same as the perpetrator if this symbol is part of its 
    //  core symbol graph.
    var namespace:Module
    {
        self.route.namespace
    }
    var residency:Package 
    {
        self.route.namespace.nationality
    }
    var orientation:_SymbolLink.Orientation
    {
        self.shape.orientation
    }
    var display:Display 
    {
        .init(path: self.path, shape: self.shape)
    }
}
extension Symbol.Intrinsic:CustomStringConvertible 
{
    public
    var description:String 
    {
        self.path.description
    }
}

extension Symbol
{
    struct Divergence:Sendable 
    {
        var metadata:AlternateHead<Metadata?>?
        var declaration:AlternateHead<Declaration<Symbol>>?
        var documentation:AlternateHead<DocumentationExtension<Symbol>>?

        init() 
        {
            self.metadata = nil
            self.declaration = nil
            self.documentation = nil
        }

        var isEmpty:Bool
        {
            if  case nil = self.metadata, 
                case nil = self.declaration,
                case nil = self.documentation
            {
                return true
            }
            else
            {
                return false
            }
        }
    }
}
extension Symbol.Divergence:BranchDivergence
{
    typealias Key = Symbol

    struct Base
    {
        var metadata:OriginalHead<Symbol.Metadata?>?
        var declaration:OriginalHead<Declaration<Symbol>>?
        var documentation:OriginalHead<DocumentationExtension<Symbol>>?

        init()
        {
            self.metadata = nil 
            self.declaration = nil
            self.documentation = nil
        }
    }

    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.metadata.revert(to: rollbacks.metadata.symbols)
        self.declaration.revert(to: rollbacks.data.declarations)
        self.documentation.revert(to: rollbacks.data.cascadingDocumentation)
    }
}
extension Symbol.Divergence.Base:IntrinsicDivergenceBase
{
    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.metadata.revert(to: rollbacks.metadata.symbols)
        self.declaration.revert(to: rollbacks.data.declarations)
        self.documentation.revert(to: rollbacks.data.cascadingDocumentation)
    }
}
