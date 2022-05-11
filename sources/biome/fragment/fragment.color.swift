import SwiftSyntax
import SwiftSyntaxParser

extension Fragment 
{
    enum ColorError:Error 
    {
        case undefined(color:String)
    }
    enum Color:UInt8, Sendable
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
    
    static 
    func highlight(_ code:String) -> [(text:String, color:Color)]
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
    func highlight(tree:Syntax) -> [(text:String, color:Color)]
    {
        var highlights:[(text:String, color:Color)] = []
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
        while case .newlines? = highlights.last?.color 
        {
            highlights.removeLast()
        }
        return highlights
    }
    static 
    func highlight(token:TokenSyntax) -> (text:String, color:Color)
    {
        let color:Color 
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
    static 
    func highlight(trivia:TriviaPiece) -> (text:String, color:Color)
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