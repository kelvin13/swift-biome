import SymbolSource

public
struct RawSymbolGraph:Sendable
{
    let id:PackageIdentifier, 
        cultures:[RawCulturalGraph], 
        snippets:[SnippetFile]
    
    public
    init(id:PackageIdentifier, 
        cultures:[RawCulturalGraph], 
        snippets:[SnippetFile])
    {
        self.id = id
        self.cultures = cultures
        self.snippets = snippets
    }
}