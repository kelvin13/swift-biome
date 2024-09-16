import SymbolSource

extension SymbolGraph
{
    @frozen public
    struct ColonialPartition:Equatable
    {
        @usableFromInline
        let namespace:ModuleIdentifier, 
            vertices:Range<Int>
    }
}