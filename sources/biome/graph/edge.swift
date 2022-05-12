import Grammar 
import JSON

struct Edge:Hashable, Sendable
{
    // https://github.com/apple/swift/blob/main/lib/SymbolGraphGen/Edge.h
    enum Kind:String, Sendable
    {
        case feature                = "_featureOf"
        case member                 = "memberOf"
        case conformer              = "conformsTo"
        case subclass               = "inheritsFrom"
        case override               = "overrides"
        case requirement            = "requirementOf"
        case optionalRequirement    = "optionalRequirementOf"
        case defaultImplementation  = "defaultImplementationOf"
    }
    // https://github.com/apple/swift/blob/main/lib/SymbolGraphGen/Edge.cpp
    var kind:Kind
    var source:Symbol.ID
    var target:Symbol.ID
    var origin:Symbol.ID?
    var constraints:[Generic.Constraint<Symbol.ID>]
}
extension Edge 
{
    init(from json:JSON) throws
    {
        (self.kind, self.origin, source: self.source, target: self.target, self.constraints) = 
            try json.lint(["targetFallback"])
        {
            var kind:Edge.Kind = try $0.remove("kind") { try $0.case(of: Edge.Kind.self) }
            let target:Symbol.ID = try $0.remove("target", Symbol.ID.init(from:))
            let origin:Symbol.ID? = try $0.pop("sourceOrigin")
            {
                try $0.lint(["displayName"])
                {
                    try $0.remove("identifier", Symbol.ID.init(from:))
                }
            }
            let usr:Symbol.USR = try $0.remove("source")
            {
                let text:String = try $0.as(String.self)
                return try Grammar.parse(text.utf8, as: Symbol.USR.Rule<String.Index>.self)
            }
            let source:Symbol.ID
            switch (kind, usr)
            {
            case (_,       .natural(let natural)): 
                source  = natural 
            // synthesized symbols can only be members of the type in their id
            case (.member, .synthesized(from: let generic, for: target)):
                source  = generic 
                kind    = .feature 
            case (_, _):
                fatalError("unimplemented")
                //throw SymbolError.synthetic(resolution: invalid)
            }
            return 
                (
                    kind: kind, origin: origin, source: source, target: target, 
                    constraints: try $0.pop("swiftConstraints", as: [JSON]?.self) 
                    { 
                        try $0.map(Generic.Constraint.init(from:)) 
                    } ?? []
                )
        }
    }
}
