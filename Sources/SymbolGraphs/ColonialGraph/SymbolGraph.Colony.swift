import SymbolSource

extension SymbolGraph
{
    @frozen public
    struct Colony
    {
        public
        let namespace:ModuleIdentifier
        public
        let culture:ModuleIdentifier

        public
        let startIndex:Int
        public
        let endIndex:Int

        @usableFromInline
        let identifiers:[SymbolIdentifier],
            vertices:[SymbolGraph.Vertex<Int>]
        
        @inlinable public
        init(partition:SymbolGraph.ColonialPartition, 
            identifiers:[SymbolIdentifier],
            vertices:[SymbolGraph.Vertex<Int>],
            culture:ModuleIdentifier)
        {
            self.culture = culture
            self.namespace = partition.namespace

            self.startIndex = partition.vertices.lowerBound
            self.endIndex = partition.vertices.upperBound

            self.identifiers = identifiers
            self.vertices = vertices
        }
    }
}
extension SymbolGraph.Colony:RandomAccessCollection
{
    @inlinable public
    subscript(index:Int) -> (id:SymbolIdentifier, intrinsic:SymbolGraph.Intrinsic)
    {
        (self.identifiers[index], self.vertices[index].intrinsic)
    }
}