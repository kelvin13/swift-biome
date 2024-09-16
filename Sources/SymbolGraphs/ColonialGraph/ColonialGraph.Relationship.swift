import JSON
import SymbolSource

extension ColonialGraph 
{
    struct Relationship:Sendable
    {
        let edge:SymbolGraph.Edge<SymbolIdentifier> 
        let origin:SymbolIdentifier?

        var hint:SymbolGraph.Hint<SymbolIdentifier>?
        {
            self.origin.map { .init(source: self.edge.source, origin: $0) }
        }
    }
}

extension ColonialGraph.Relationship 
{
    init(from json:JSON) throws
    {
        (self.edge, self.origin) = try json.lint(whitelisting: ["targetFallback"])
        {
            let target:SymbolIdentifier = try $0.remove("target", SymbolIdentifier.init(from:))
            let source:USR = try $0.remove("source", as: String.self)
            {
                try .init(parsing: $0.utf8)
            }
            // https://github.com/apple/swift/blob/main/lib/SymbolGraphGen/Edge.h
            let edge:SymbolGraph.Edge<SymbolIdentifier>
            switch (source, try $0.remove("kind", as: String.self))
            {
            case (.synthesized(from: let source, for: target), "memberOf"):
                // only 'memberOf' edges may come from synthetic sources
                edge = .init(source, is: .feature, of: target)
            
            case (.natural(let source), "memberOf"):
                edge = .init(source, is: .member, of: target)
            case (.natural(let source), "conformsTo"):
                // only 'conformsTo' edges may contain constraints 
                let constraints:[Generic.Constraint<SymbolIdentifier>] = 
                    try $0.pop("swiftConstraints", as: [JSON]?.self) 
                { 
                    try $0.map(Generic.Constraint.init(lowering:)) 
                } ?? []
                edge = .init(source, is: .conformer(constraints), of: target)
            case (.natural(let source), "inheritsFrom"):
                edge = .init(source, is: .subclass, of: target)
            case (.natural(let source), "overrides"):
                edge = .init(source, is: .override, of: target)
            case (.natural(let source), "requirementOf"):
                edge = .init(source, is: .requirement, of: target)
            case (.natural(let source), "optionalRequirementOf"):
                edge = .init(source, is: .optionalRequirement, of: target)
            case (.natural(let source), "defaultImplementationOf"):
                edge = .init(source, is: .defaultImplementation, of: target)
            
            case (.natural(_), let kind): 
                throw ColonialGraphDecodingError.unknownRelationshipKind(kind)
            case (let source, let kind): 
                throw ColonialGraphDecodingError.invalidRelationshipKind(source, is: kind)
            }

            let origin:SymbolIdentifier? = try $0.pop("sourceOrigin")
            {
                try $0.lint(whitelisting: ["displayName"])
                {
                    try $0.remove("identifier", SymbolIdentifier.init(from:))
                }
            }
            return (edge, origin)
        }
    }
}