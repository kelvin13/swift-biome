import Grammar

extension Multipart
{
    @inlinable public static
    func escape(_ string:some StringProtocol) -> String
    {
        var escaped:String = "\""
        for character:Character in string 
        {
            switch character
            {
            case "\"":      escaped += "\\\""
            case "\\":      escaped += "\\\\"
            default:        escaped.append(character)
            }
        }
        escaped += "\""
        return escaped
    }
}

extension Multipart
{
    public
    enum Rule<Location>
    {
        public
        typealias Encoding = UnicodeEncoding<Location, UInt8>
    }
}
extension Multipart.Rule
{
    // https://httpwg.org/specs/rfc9110.html#whitespace
    public
    enum Whitespace:TerminalRule
    {
        public
        typealias Terminal = UInt8
        public
        typealias Construction = Void

        @inlinable public static 
        func parse(terminal:UInt8) -> Void?
        {
            switch terminal
            {
            case 0x09, 0x20: // '\t', ' '
                return ()
            default:
                return nil
            }
        }
    }
    // https://httpwg.org/specs/rfc9110.html#tokens
    public
    enum TokenElement:TerminalRule
    {
        public
        typealias Terminal = UInt8
        public
        typealias Construction = Void

        @inlinable public static 
        func parse(terminal:UInt8) -> Void?
        {
            switch terminal
            {
            case    0x30 ... 0x39,  // [0-9]
                    0x41 ... 0x5a,  // [A-Z]
                    0x61 ... 0x7a,  // [a-z]
                    0x21,   // !
                    0x23,   // #
                    0x24,   // $
                    0x25,   // %
                    0x26,   // &
                    0x27,   // '
                    0x2a,   // *
                    0x2b,   // +
                    0x2d,   // -
                    0x2e,   // .
                    0x5e,   // ^
                    0x5f,   // _
                    0x60,   // `
                    0x7c,   // |
                    0x7e:   // ~
                return ()
            default:
                return nil
            }
        }
    }
    public
    enum Token:ParsingRule
    {
        public
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> String
            where Source:Collection<UInt8>, Source.Index == Location
        {
            let start:Location = input.index
            try input.parse(as: TokenElement.self)
                input.parse(as: TokenElement.self, in: Void.self)
            return .init(decoding: input[start ..< input.index], as: Unicode.ASCII.self)
        }
    }
}
extension Multipart.Rule
{
    // https://httpwg.org/specs/rfc9110.html#quoted.strings
    public 
    enum QuotedStringElement:TerminalRule
    {
        public 
        typealias Terminal = UInt8
        public 
        typealias Construction = Void 

        @inlinable public static 
        func parse(terminal:UInt8) -> Void? 
        {
            switch terminal 
            {
            case    0x09,   // '\t'
                    0x20 ... 0x21, 
                    0x23 ... 0x5b, 
                    0x5d ... 0x7e,
                    0x80 ... 0xff:
                return () 
            default:
                return nil
            }
        }
    } 
    public 
    enum QuotedStringEscapedElement:TerminalRule 
    {
        public 
        typealias Terminal      = UInt8
        public 
        typealias Construction  = Unicode.Scalar 
        @inlinable public static 
        func parse(terminal:UInt8) -> Unicode.Scalar? 
        {
            switch terminal 
            {
            case    0x09,           // '\t'
                    0x20 ... 0x7e,  // ' ', VCHAR
                    0x80 ... 0xff:
                return .init(terminal)
            default:
                return nil
            }
        }
    }
    public 
    enum QuotedStringEscapeSequence:ParsingRule 
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> Unicode.Scalar
            where Source:Collection<UInt8>, Source.Index == Location
        {
            try input.parse(as: Encoding.Backslash.self)
            return try input.parse(as: QuotedStringEscapedElement.self)
        }
    }
    public 
    enum QuotedString:ParsingRule 
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> String
            where Source:Collection<UInt8>, Source.Index == Location
        {
            try input.parse(as: Encoding.DoubleQuote.self)
            
            let start:Location = input.index 
            input.parse(as: QuotedStringElement.self, in: Void.self)
            let end:Location = input.index 
            var string:String = .init(decoding: input[start ..< end], as: Unicode.UTF8.self)
            
            while let next:Unicode.Scalar = input.parse(as: QuotedStringEscapeSequence?.self)
            {
                string.append(Character.init(next))
                let start:Location = input.index 
                input.parse(as: QuotedStringElement.self, in: Void.self)
                let end:Location = input.index 
                string += .init(decoding: input[start ..< end], as: Unicode.UTF8.self)
            }
            
            try input.parse(as: Encoding.DoubleQuote.self)
            return string 
        }
    }
}
extension Multipart.Rule
{
    public 
    enum Parameter:ParsingRule 
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> (name:String, value:String)
            where Source:Collection<UInt8>, Source.Index == Location
        {
            input.parse(as: Whitespace.self, in: Void.self)

            try input.parse(as: Encoding.Semicolon.self)
            
            input.parse(as: Whitespace.self, in: Void.self)

            let name:String = try input.parse(as: Token.self)
            try input.parse(as: Encoding.Equals.self)
            if let value:String = input.parse(as: Token?.self)
            {
                return (name.lowercased(), value)
            }
            else
            {
                return (name.lowercased(), try input.parse(as: QuotedString.self))
            }
        }
    }
}
extension Multipart.Rule
{
    public 
    enum SubHeaderValueElement:TerminalRule 
    {
        public 
        typealias Terminal      = UInt8
        public 
        typealias Construction  = Void
        @inlinable public static 
        func parse(terminal:UInt8) -> Void? 
        {
            switch terminal 
            {
            case    0x09,           // '\t'
                    0x20 ... 0x7e,  // ' ', VCHAR
                    0x80 ... 0xff:
                return ()
            default:
                return nil
            }
        }
    }

    public 
    enum SubHeaders:ParsingRule 
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> Multipart.FormItem.Metadata
            where Source:Collection<UInt8>, Source.Index == Location
        {
            var disposition:DispositionType? = nil
            var content:MediaType? = nil
            while case (let field, _)? = try? input.parse(as: (Token, Encoding.Colon).self)
            {
                input.parse(as: Whitespace.self, in: Void.self)

                switch field.lowercased()
                {
                case "content-disposition":
                    disposition = try input.parse(as: DispositionType.Rule<Location>.self)
                    input.parse(as: Whitespace.self, in: Void.self)
                
                case "content-type":
                    content = try input.parse(as: MediaType.Rule<Location>.self)
                    input.parse(as: Whitespace.self, in: Void.self)
                
                default:
                    // includes ``Whitespace`` characters
                    input.parse(as: SubHeaderValueElement.self, in: Void.self)
                }

                try input.parse(as: Encoding.CarriageReturn.self)
                try input.parse(as: Encoding.Linefeed.self)
            }

            try input.parse(as: Encoding.CarriageReturn.self)
            try input.parse(as: Encoding.Linefeed.self)

            return try .init(disposition: disposition, content: content)
        }
    }
}
