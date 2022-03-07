import SwiftSyntax
import SwiftSyntaxParser

@available(*, deprecated)
public 
typealias Language = SwiftLanguage

enum SwiftHighlight:UInt8, Sendable
{
    //  special semantic identifiers. only generated by the symbolgraph extractor
    case generic = 0
    case argument
    case parameter
    
    /// an attribute like '@frozen'
    case attribute
    /// a type annotation, which appears after a colon. not all references to a 
    /// type have this classification, some references are considered identifiers
    /// an ordinary identifier, or a keyword identifier like 'init', 'deinit', and 'subscript'
    case keywordIdentifier
    case keywordDirective
    case keywordText 
    
    case identifier
    case directive
    case text
    case type
    case newlines
    /// a directive like '#warning', directive-keyword like '#if'.
    /// other text, including keywords like 'if', 'var', 'func', etc.
    
    case pseudo
    case number
    case string 
    case interpolation
    case comment
    case documentationComment
    
    case invalid
}
extension SwiftHighlight 
{
    static 
    func highlight(_ code:String) -> [(text:String, highlight:Self)]
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
    static 
    func highlight(tree:Syntax) -> [(text:String, highlight:Self)]
    {
        var highlights:[(text:String, highlight:Self)] = []
        for token:TokenSyntax in tree.tokens 
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
        while case .newlines? = highlights.last?.highlight 
        {
            highlights.removeLast()
        }
        return highlights
    }
    static 
    func highlight(token:TokenSyntax) -> (text:String, highlight:Self)
    {
        let highlight:Self 
        switch token.tokenClassification.kind 
        {
        case .keyword:
            switch token.tokenKind 
            {
            case    .initKeyword,
                    .deinitKeyword,
                    .subscriptKeyword:          highlight = .keywordIdentifier
            default:                            highlight = .keywordText
            }
        case .none:                             highlight = .text
            
        case .identifier:                       highlight = .identifier
        case .typeIdentifier:                   highlight = .type
        case .dollarIdentifier:                 highlight = .pseudo
        case .integerLiteral:                   highlight = .number 
        case .floatingLiteral:                  highlight = .number
        case .stringLiteral:                    highlight = .string 
        case .stringInterpolationAnchor:        highlight = .interpolation
        case .poundDirectiveKeyword:            highlight = .directive
        case .buildConfigId:                    highlight = .keywordDirective
        case .attribute:                        highlight = .attribute
        // only used by xcode 
        case .objectLiteral:                    highlight = .text
        case .editorPlaceholder:                highlight = .text
        case .lineComment, .blockComment:       highlight = .comment
        case .docLineComment, .docBlockComment: highlight = .documentationComment
        }
        return (token.text, highlight)
    }
    static 
    func highlight(trivia:TriviaPiece) -> (text:String, highlight:Self)
    {
        switch trivia 
        {
        case .garbageText(let text): 
            return (text, .invalid)
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

public 
enum SwiftLanguage 
{
    public 
    struct Constraint<Link>
    {
        enum Verb
        {
            case inherits(from:Link?)
            case conforms(to:Link?)
            case `is`(Link?)
        }
        
        var subject:String
        var verb:Verb 
        var object:String
    }
}
extension SwiftLanguage.Constraint:Sendable where Link:Sendable {}
