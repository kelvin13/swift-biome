import SymbolSource

extension SymbolGraph
{
    @frozen public
    struct CulturalPartition:Equatable
    {
        @usableFromInline
        let id:ModuleIdentifier 
        @usableFromInline
        let dependencies:[PackageDependency], 
            markdown:[MarkdownFile],
            sources:[SwiftFile]
        @usableFromInline
        var colonies:[ColonialPartition],
            vertices:Range<Int>,
            edges:[Edge<Int>]
    }
}
