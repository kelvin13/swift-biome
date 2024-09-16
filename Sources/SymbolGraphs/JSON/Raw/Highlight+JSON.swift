import JSON
import SymbolSource

extension Highlight
{
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
            throw ColonialGraphDecodingError.unknownFragmentKind(kind)
        }
    }
}
