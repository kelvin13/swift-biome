import SymbolSource

extension SymbolGraph
{
    @frozen public
    struct Identifiers:Equatable
    {
        public
        let table:[SymbolIdentifier]
        @usableFromInline
        let cohorts:[Range<Int>]
    }
    @frozen public
    struct ExternalIdentifiers
    {
        @usableFromInline
        let identifiers:Identifiers

        @inlinable public
        init(_ identifiers:Identifiers)
        {
            self.identifiers = identifiers
        }
    }
}
extension SymbolGraph.Identifiers
{
    @inlinable public
    var external:SymbolGraph.ExternalIdentifiers
    {
        .init(self)
    }
}
extension SymbolGraph.ExternalIdentifiers:RandomAccessCollection
{
    @inlinable public
    var startIndex:Int
    {
        self.identifiers.cohorts.startIndex
    }
    @inlinable public
    var endIndex:Int
    {
        self.identifiers.cohorts.endIndex
    }
    @inlinable public
    subscript(index:Int) -> ArraySlice<SymbolIdentifier>
    {
        self.identifiers.table[self.identifiers.cohorts[index]]
    }
}