import JSON
import Notebook
import SymbolAvailability
import SymbolSource

extension ColonialGraph 
{
    struct Symbol:Identifiable, Sendable
    {
        enum ID:Hashable, Sendable
        {
            case natural(SymbolIdentifier)
            // namespace of natural base, *not* its culture, and *not* the 
            // culture of the synthesized feature!
            case synthesized(SymbolIdentifier, namespace:ModuleIdentifier) 

            var symbol:SymbolIdentifier 
            {
                switch self 
                {
                case .natural(let symbol), .synthesized(let symbol, namespace: _):
                    return symbol
                }
            }
        }
        struct Location:Sendable 
        {
            let uri:String 
            let line:Int 
            let character:Int
        }
        
        let id:ID
        let location:Location?
        var vertex:SymbolGraph.Vertex<SymbolIdentifier>
    }
}

extension ColonialGraph.Symbol
{
    public 
    init(from json:JSON) throws 
    {
        (self.id, self.location, self.vertex) = try json.lint 
        {
            let (extendedModule, extensionConstraints):
            (
                ModuleIdentifier?, 
                [Generic.Constraint<SymbolIdentifier>]
            ) = try $0.pop("swiftExtension")
            {
                try $0.lint(whitelisting: ["typeKind"])
                {
                    (
                        try $0.pop("extendedModule", as: String.self, ModuleIdentifier.init(_:)),
                        try $0.pop("constraints", as: [JSON]?.self) 
                        { 
                            try $0.map(Generic.Constraint<SymbolIdentifier>.init(lowering:)) 
                        } ?? []
                    )
                }
            } ?? (nil, [])
            let (generics, genericConstraints):
            (
                [Generic], 
                [Generic.Constraint<SymbolIdentifier>]
            ) = try $0.pop("swiftGenerics")
            {
                try $0.lint 
                {
                    (
                        try $0.pop("parameters", as: [JSON]?.self) 
                        { 
                            try $0.map(Generic.init(lowering:)) 
                        } ?? [],
                        try $0.pop("constraints", as: [JSON]?.self) 
                        { 
                            try $0.map(Generic.Constraint.init(lowering:)) 
                        } ?? []
                    )
                }
            } ?? ([], [])
            
            let id:ID = try $0.remove("identifier")
            {
                try $0.lint(whitelisting: ["interfaceLanguage"])
                {
                    try $0.remove("precise", as: String.self)
                    {
                        switch try USR.init(parsing: $0.utf8)
                        {
                        case .natural(let id): 
                            return .natural(id)
                        case .synthesized(from: let id, for: _): 
                            // synthesized symbols always live in extensions
                            guard let extendedModule:ModuleIdentifier 
                            else 
                            {
                                // FIXME: we should throw an error instead 
                                fatalError("FIXME")
                            }
                            return .synthesized(id, namespace: extendedModule)
                        }
                    }
                }
            }
            let path:Path = try $0.remove("pathComponents", Path.init(from:))
            let shape:Shape = try $0.remove("kind")
            {
                try $0.lint(whitelisting: ["displayName"])
                {
                    try $0.remove("identifier", as: String.self) 
                    { 
                        if  let shape:Shape = .init(declarationKind: $0, 
                            global: path.count == 1)
                        {
                            return shape 
                        }
                        else 
                        {
                            throw ColonialGraphDecodingError.unknownDeclarationKind($0)
                        }
                    }
                }
            }
            
            let _:AccessLevel = try $0.remove("accessLevel") { try $0.as(cases: AccessLevel.self) }
            let _:Bool = try $0.pop("spi", as: Bool.self) ?? false
            
            let fragments:Notebook<Highlight, SymbolIdentifier> = 
                try $0.remove("declarationFragments", Notebook<Highlight, SymbolIdentifier>.init(lowering:)) 
            let signature:Notebook<Highlight, Never> = 
                try $0.remove("names")
            {
                try $0.lint(whitelisting: ["title", "navigator"])
                {
                    try $0.remove("subHeading", Notebook<Highlight, Never>.init(lowering:)) 
                }
            }
            let location:Location? = try $0.pop("location", Location.init(from:))
            let _:JSON? = $0.pop("functionSignature")

            let availability:Availability = 
                try $0.pop("availability", as: [JSON]?.self, Availability.init(lowering:)) ?? .init()
            let comment:String? = try $0.pop("docComment")
            {
                try $0.lint(whitelisting: ["uri", "module"]) 
                {
                    try $0.remove("lines", as: [JSON].self)
                    {
                        try $0.map
                        {
                            try $0.lint(whitelisting: ["range"])
                            {
                                try $0.remove("text", as: String.self)
                            }
                        }.joined(separator: "\n")
                    }
                }
            }
            let vertex:SymbolGraph.Vertex = .init(
                intrinsic: .init(shape: shape, path: path),
                declaration: .init(
                    fragments: fragments, 
                    signature: signature, 
                    availability: availability, 
                    extensionConstraints: extensionConstraints, 
                    genericConstraints: genericConstraints, 
                    generics: generics), 
                comment: .init(comment))
            return (id, location, vertex)
        }
    }
}
extension ColonialGraph.Symbol.Location
{
    init(from json:JSON) throws 
    {
        (self.uri, self.line, self.character) = try json.lint 
        {
            let uri:String                      = try $0.remove("uri", as: String.self)
            let (line, character):(Int, Int)    = try $0.remove("position")
            {
                try $0.lint 
                {
                    (
                        try $0.remove("line",      as: Int.self),
                        try $0.remove("character", as: Int.self)
                    )
                }
            }
            return (uri, line, character)
        }
    }
}