import SymbolSource
import SwiftSyntaxParser
import SwiftSyntax
import IDEUtils

extension Extension.Renderer 
{
    enum CodeBlockLanguage:String 
    {
        case swift  = "swift"
        case text   = "text"
    }
    
    static 
    func highlight(_ code:String) -> [(text:String, color:Highlight)]
    {
        do 
        {
            return Self.highlight(tree: .init(try SyntaxParser.parse(source: code)))
        }
        catch let error 
        {
            return 
                [
                    ("//  highlighting error:", .comment), 
                    ("\n",                      .newlines),
                    ("//  \(error)",            .comment),
                ]
                + 
                code.split(separator: "\n", omittingEmptySubsequences: false).map 
                {
                    [
                        ("\n",                  .newlines),
                        (String.init($0),       .comment),
                    ]
                }.joined()
        }
    }
    private static 
    func highlight(tree:Syntax) -> [(text:String, color:Highlight)]
    {
        var highlights:[(text:String, color:Highlight)] = []
        for token:TokenSyntax in tree.tokens(viewMode: .sourceAccurate) 
        {
            for trivia:TriviaPiece in token.leadingTrivia 
            {
                highlights.append(Self.highlight(trivia: trivia))
            }
            if !token.text.isEmpty
            {
                highlights.append(Self.highlight(token: token))
            }
            for trivia:TriviaPiece in token.trailingTrivia
            {
                highlights.append(Self.highlight(trivia: trivia))
            }
        }
        // strip trailing newlines 
        while case .newlines? = highlights.last?.color 
        {
            highlights.removeLast()
        }
        return highlights
    }
    private static 
    func highlight(token:TokenSyntax) -> (text:String, color:Highlight)
    {
        let color:Highlight 
        switch token.tokenClassification.kind 
        {
        case .keyword:
            switch token.tokenKind 
            {
            case    .initKeyword,
                    .deinitKeyword,
                    .subscriptKeyword:          color = .keywordIdentifier
            default:                            color = .keywordText
            }
        case .none:                             color = .text
            
        case .identifier:                       color = .identifier
        case .operatorIdentifier:               color = .identifier
        case .typeIdentifier:                   color = .type
        case .dollarIdentifier:                 color = .pseudo
        case .integerLiteral:                   color = .number 
        case .floatingLiteral:                  color = .number
        case .stringLiteral:                    color = .string 
        case .stringInterpolationAnchor:        color = .interpolation
        case .poundDirectiveKeyword:            color = .directive
        case .buildConfigId:                    color = .keywordDirective
        case .attribute:                        color = .attribute
        // only used by xcode 
        case .objectLiteral:                    color = .text
        case .editorPlaceholder:                color = .text
        case .lineComment, .blockComment:       color = .comment
        case .docLineComment, .docBlockComment: color = .documentationComment
        }
        return (token.text, color)
    }
    private static 
    func highlight(trivia:TriviaPiece) -> (text:String, color:Highlight)
    {
        switch trivia 
        {
        case .unexpectedText(let text): 
            return (text, .invalid)
        case .shebang(let text): 
            return (text, .text)
        case .spaces(let count):
            return (.init(repeating: " ", count: count), .text)
        case .tabs(let count): 
            return (.init(repeating: " ", count: count * 4), .text)
        case .verticalTabs(let count), .formfeeds(let count):
            return (.init(repeating: " ", count: count), .text)
        case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
            return (.init(repeating: "\n", count: count), .newlines)
        case .lineComment(let string), .blockComment(let string):
            return (string, .comment)
        case .docLineComment(let string), .docBlockComment(let string):
            return (string, .documentationComment)
        }
    }
}
