import HTML
import Notebook
import SymbolSource

protocol SignatureCard:HTMLElementConvertible
{
    associatedtype Signature:Sequence<Notebook<Highlight, Never>.Fragment>

    var signature:Signature { get }
    var overview:[UInt8]? { get }
    var uri:String { get }
}
extension SignatureCard 
{
    var html:HTML.Element<Never>
    {
        let signature:HTML.Element<Never> = .a(.highlight(signature: self.signature), 
            attributes: [.href(self.uri), .class("signature")])
        if  let utf8:[UInt8] = self.overview
        {
            return .li(signature, .init(node: .value(.init(escaped: _move utf8))))
        }
        else 
        {
            return .li(signature)
        }
    }
}