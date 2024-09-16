import Notebook
import SymbolSource

struct ModuleCard:SignatureCard
{
    let reference:ModuleReference
    let overview:[UInt8]?

    init(reference:ModuleReference, overview:[UInt8]?)
    {
        self.reference = reference
        self.overview = overview
    }

    var namespace:ModuleIdentifier 
    {
        self.reference.name
    }
    var uri:String 
    {
        self.reference.uri
    }
    var signature:[Notebook<Highlight, Never>.Fragment] 
    {
        [
            .init("import", color: .keywordText),
            .init(" ", color: .text),
            .init(self.namespace.string, color: .identifier),
        ]
    }

    static 
    func |<| (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.namespace < rhs.namespace
    }
}