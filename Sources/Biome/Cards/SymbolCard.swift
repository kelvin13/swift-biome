import Notebook
import SymbolSource

struct SymbolCard:SignatureCard
{
    let signature:Notebook<Highlight, Never>
    let overview:[UInt8]?
    let uri:String 

    init(signature:Notebook<Highlight, Never>, 
        overview:[UInt8]?, 
        uri:String)
    {
        self.signature = signature
        self.overview = overview
        self.uri = uri
    }
}