import HTML
import Notebook
import SymbolSource

extension Highlight
{
    fileprivate
    var `class`:String?
    {
        switch self
        {
        case .text: 
            return nil
        case .type:
            return "syntax-type"
        case .identifier:
            return "syntax-identifier"
        case .generic:
            return "syntax-generic"
        case .argument:
            return "syntax-parameter-label"
        case .parameter:
            return "syntax-parameter-name"
        case .directive, .attribute, .keywordText:
            return "syntax-keyword"
        case .keywordIdentifier:
            return "syntax-keyword syntax-keyword-identifier"
        case .pseudo:
            return "syntax-pseudo-identifier"
        case .number, .string:
            return "syntax-literal"
        case .interpolation:
            return "syntax-interpolation-anchor"
        case .keywordDirective:
            return "syntax-macro"
        case .newlines:
            return "syntax-newline"
        case .comment, .documentationComment:
            return "syntax-comment"
        case .invalid:
            return "syntax-invalid"
        }
    }
}
extension HTML.Element
{
    static 
    func highlight(escaped string:String, _ color:Highlight, uri:String? = nil) -> Self
    {
        .highlight(.init(escaped: string), color, uri: uri)
    }
    static 
    func highlight(_ string:String, _ color:Highlight, uri:String? = nil) -> Self
    {
        .highlight(.init(string), color, uri: uri)
    }
    static 
    func highlight(_ child:Self, _ color:Highlight, uri:String? = nil) -> Self
    {
        guard let color:String = color.class 
        else 
        {
            return child
        }
        if let uri:String 
        {
            return    .a(child, attributes: [.class(color), .href(uri)])
        }
        else 
        {
            return .span(child, attributes: [.class(color)])
        }
    } 
}
extension HTML.Element
{
    static 
    func highlight(_ fragment:Notebook<Highlight, Never>.Fragment) -> Self
    {
        fragment.color.class.map { .span(fragment.text, attributes: [.class($0)]) } ?? 
            .init(fragment.text)
    }
    static 
    func highlight(signature:some Sequence<Notebook<Highlight, Never>.Fragment>) -> Self
    {
        return .code(signature.map(Self.highlight(_:)))
    }
}