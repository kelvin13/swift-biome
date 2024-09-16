import SymbolSource

public
struct RawColonialGraph:Sendable
{
    let namespace:ModuleIdentifier,
        culture:ModuleIdentifier,
        utf8:[UInt8]
    
    public
    init(namespace:ModuleIdentifier, culture:ModuleIdentifier, utf8:[UInt8])
    {
        self.namespace = namespace
        self.culture = culture
        self.utf8 = utf8
    }
}