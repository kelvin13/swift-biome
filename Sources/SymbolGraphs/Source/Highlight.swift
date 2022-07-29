import JSON

@frozen public
enum Highlight:UInt8, Sendable
{
    //  special semantic identifiers. only generated by the symbolgraph extractor
    case generic = 0
    case argument
    case parameter
    
    /// an attribute like '@frozen'
    case attribute
    case comment
    /// '#warning', etc.
    case directive
    case documentationComment
    case identifier
    case interpolation
    case invalid
    /// 'init', 'deinit', 'subscript'
    case keywordIdentifier
    /// '#if', '#else', etc.
    case keywordDirective
    /// 'for', 'let', 'func', etc.
    case keywordText 
    case newlines
    case number
    // '$0'
    case pseudo
    case string 
    case text
    /// A type annotation, which appears after a colon. Not all references to a 
    /// type have this classification; some references are considered identifiers.
    case type

    init(from json:JSON, text:String) throws 
    {
        // https://github.com/apple/swift/blob/main/lib/SymbolGraphGen/DeclarationFragmentPrinter.cpp
        switch try json.as(String.self) as String
        {
        case "keyword":
            switch text 
            {
            case "init", "deinit", "subscript":
                                    self =  .keywordIdentifier
            default:                self =  .keywordText
            }
        case "attribute":           self =  .attribute
        case "number":              self =  .number
        case "string":              self =  .string
        case "identifier":          self =  .identifier
        case "typeIdentifier":      self =  .type
        case "genericParameter":    self =  .generic
        case "internalParam":       self =  .parameter
        case "externalParam":       self =  .argument
        case "text":                self =  .text
        case let kind:
            throw SymbolGraphDecodingError.unknownFragmentKind(kind)
        }
    }
}
