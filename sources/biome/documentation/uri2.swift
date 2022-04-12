import Grammar

struct URI 
{
    var path:[LexicalPath.Vector?]
    var query:[(key:String, value:String)]
    
    struct LexicalPath 
    {
        enum Vector
        {
            /// '..'
            case pop 
            /// A regular path component. This can be '.' or '..' if at least one 
            /// of the dots was percent-encoded.
            case push(String)
        }
        enum Segmentation<Location> where Location:Comparable
        {
            case opaque(Location) // end index
            case version(Package.Version)
            case big
            case little(Location) // start index 
            case reveal(big:Location, little:Location) // end index, start index
        }
        enum Component 
        {
            case identifiers(String, hyphen:String.Index)
            case identifier(String)
            case version(Package.Version)
        }
        enum Orientation:Unicode.Scalar
        {
            case gay        = "."
            case straight   = "/"
        }
        
        var orientation:Orientation
        var components:[Component]
        var visible:Int 
        
        init<S>(normalizing string:S) throws where S:StringProtocol 
        {
            //  i. lexical segmentation and percent-decoding 
            //
            //  '//foo/bar/.\bax.qux/..//baz./.Foo/%2E%2E//' becomes 
            // ['', 'foo', 'bar', < None >, 'bax.qux', < Self >, '', 'baz.bar', '.Foo', '..', '', '']
            // 
            //  the first slash '/' does not generate an empty component.
            //  this is the uri we percieve as the uri entered by the user, even 
            //  if their slash ('/' vs '\') or percent-encoding scheme is different.
            try self.init(normalizing: 
                try Grammar.parse(string.utf8, as: [Rule<String.Index, UInt8>.Vector].self))
        }
        init(normalizing vectors:[Vector?]) throws
        {
            // ii. lexical normalization 
            //
            // ['', 'foo', 'bar', < nil >, 'bax.qux', < Self >, '', 'baz.bar', '.Foo', '..', '', ''] becomes 
            // [    'foo', 'bar',                                   'baz.bar', '.Foo', '..']
            //                                                      ^~~~~~~~~~~~~~~~~~~~~~~
            //                                                      (visible = 3)
            //  if `Self` components would erase past the beginning of the components list, 
            //  the extra `Self` components are ignored.
            //  redirects generated from this step are PERMANENT. 
            //  paths containing `nil` and empty components always generate redirects.
            //  however, the presence and location of an empty component can be meaningful 
            //  in a symbollink.    
            var components:[String] = []
                components.reserveCapacity(vectors.count)
            var fold:Int = components.endIndex
            for vector:Vector? in vectors
            {
                switch vector 
                {
                case .pop?:
                    let _:String? = components.popLast()
                    fallthrough
                case nil: 
                    fold = components.endIndex
                case .push(let component): 
                    components.append(component)
                }
            }
            // iii. semantic segmentation 
            //
            // [     'foo',       'bar',       'baz.bar',                     '.Foo',          '..'] becomes
            // [.big("foo"), .big("bar"), .big("baz"), .little("bar"), .little("Foo"), .little("..")] 
            //                                                                         ^~~~~~~~~~~~~~~
            //                                                                          (visible = 1)
            
            // the empty path ('/') is straight
            self.orientation = .straight 
            self.components = []
            self.visible = 0
            for (index, component):(Int, String) in zip(components.indices, components)
            {
                let appended:Int 
                switch try Grammar.parse(component.unicodeScalars, 
                    as: Rule<String.Index, Unicode.Scalar>.LexicalPathComponents.self)
                {
                case .opaque(let hyphen): 
                    self.components.append(.identifiers(component, hyphen: hyphen))
                    self.orientation = .straight 
                    appended = 1
                case .big:
                    self.components.append(.identifier(component))
                    self.orientation = .straight 
                    appended = 1
                
                case .little                      (let start):
                    // an isolated little-component implies an empty big-predecessor, 
                    // and therefore resets the visibility counter
                    self.visible = 0
                    self.components.append(.identifier(String.init(component[start...])))
                    self.orientation = .gay 
                    appended = 1
                
                case .reveal(big: let end, little: let start):
                    self.components.append(.identifier(String.init(component[..<end])))
                    self.components.append(.identifier(String.init(component[start...])))
                    self.orientation = .gay 
                    appended = 2
                    
                case .version(let version):
                    self.components.append(.version(version))
                    self.orientation = .straight 
                    appended = 1
                }
                if fold <= index 
                {
                    self.visible += appended
                }
            }
        }
    }

    enum Rule<Location, Terminal>
    {
        typealias Encoding = Grammar.Encoding<Location, Terminal>
    }
    enum EncodedByte<Location>:ParsingRule
    {
        typealias Terminal = UInt8
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws -> UInt8
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any
        {
            try input.parse(as: Grammar.Encoding<Location, Terminal>.Percent.self)
            let high:UInt8  = try input.parse(as: Grammar.HexDigit<Location, Terminal, UInt8>.self)
            let low:UInt8   = try input.parse(as: Grammar.HexDigit<Location, Terminal, UInt8>.self)
            return high << 4 | low
        }
    } 
    enum EncodedString<UnencodedByte>:ParsingRule 
    where   UnencodedByte:ParsingRule, 
            UnencodedByte.Terminal == UInt8,
            UnencodedByte.Construction == Void
    {
        typealias Location = UnencodedByte.Location
        typealias Terminal = UInt8
        
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws -> (string:String, unencoded:Bool)
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any
        {
            let start:Location      = input.index 
            input.parse(as: UnencodedByte.self, in: Void.self)
            let end:Location        = input.index 
            var string:String       = .init(decoding: input[start ..< end], as: Unicode.UTF8.self)
            
            while let utf8:[UInt8]  = input.parse(as: Grammar.Reduce<EncodedByte<Location>, [UInt8]>?.self)
            {
                string             += .init(decoding: utf8,                 as: Unicode.UTF8.self)
                let start:Location  = input.index 
                input.parse(as: UnencodedByte.self, in: Void.self)
                let end:Location    = input.index 
                string             += .init(decoding: input[start ..< end], as: Unicode.UTF8.self)
            }
            return (string, end == input.index)
        }
    } 
}
extension URI.Rule where Terminal == UInt8
{
    // `Vector` and `Query` can only be defined for UInt8 because we are decoding UTF-8 to a String
    enum Vector:ParsingRule 
    {
        enum Separator:TerminalRule
        {
            typealias Construction = Void
            static 
            func parse(terminal:Terminal) -> Void? 
            {
                switch terminal 
                {
                //    '/'   '\'
                case 0x2f, 0x5c: return ()
                default: return nil
                }
            }
        }
        /// Matches a UTF-8 code unit that is allowed to appear inline in URL path component. 
        enum UnencodedByte:TerminalRule
        {
            typealias Construction = Void 
            static 
            func parse(terminal:UInt8) -> Void? 
            {
                switch terminal 
                {
                //    '%',  '/',  '\',  '?',  '#'
                case 0x25, 0x2f, 0x5c, 0x3f, 0x23:
                    return nil
                default:
                    return ()
                }
            }
        } 

        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws -> URI.LexicalPath.Vector?
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any
        {
            try input.parse(as: Separator.self)
            let (string, unencoded):(String, Bool) = try input.parse(as: URI.EncodedString<UnencodedByte>.self)
            guard unencoded
            else 
            {
                // component contained at least one percent-encoded character
                return string.isEmpty ? nil : .push(string)
            }
            switch string 
            {
            case "", ".":   return  nil
            case    "..":   return .pop
            case let next:  return .push(next)
            }
        }
    }
    enum Query:ParsingRule 
    {
        enum Separator:TerminalRule 
        {
            typealias Construction  = Void 
            static 
            func parse(terminal:UInt8) -> Void?
            {
                switch terminal
                {
                //    '&'   ';' 
                case 0x26, 0x3b: 
                    return ()
                default:
                    return nil
                }
            }
        }
        enum UnencodedByte:TerminalRule 
        {
            typealias Construction  = Void 
            static 
            func parse(terminal:UInt8) -> Void?
            {
                switch terminal
                {
                //    '&'   ';'   '='   '#'
                case 0x26, 0x3b, 0x3d, 0x23:
                    return nil 
                default:
                    return ()
                }
            }
        }
        enum Item:ParsingRule 
        {
            static 
            func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) 
                throws -> (key:String, value:String)
                where Grammar.Parsable<Location, Terminal, Diagnostics>:Any
            {
                let (key, _):(String, Bool) = try input.parse(as: URI.EncodedString<UnencodedByte>.self)
                try input.parse(as: Encoding.Equals.self)
                let (value, _):(String, Bool) = try input.parse(as: URI.EncodedString<UnencodedByte>.self)
                return (key, value)
            }
        }
        
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) 
            throws -> [(key:String, value:String)]
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any
        {
            try input.parse(as: Grammar.Join<Item, Separator, [(key:String, value:String)]>.self) 
        }
    }
}

extension URI.Rule where Terminal == Unicode.Scalar
{
    typealias Integer = Grammar.UnsignedIntegerLiteral<Grammar.DecimalDigitScalar<Location, Int>>
    
    //  Arguments ::= '(' ( IdentifierBase ':' ) + ')'
    enum Arguments:ParsingRule 
    {
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws 
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any 
        {
            try input.parse(as: Encoding.ParenthesisLeft.self)
            try input.parse(as: IdentifierBase.self)
            try input.parse(as: Encoding.Colon.self)
            // note: parse as tuple, otherwise we may accidentally accept something 
            // like 'foo(bar:baz)', which is missing the trailing colon
            while let _:(Void, Void) = try? input.parse(as: (IdentifierBase, Encoding.Colon).self)
            {
            }
            try input.parse(as: Encoding.ParenthesisRight.self)
        }
    }
    
    enum IdentifierFirst:TerminalRule 
    {
        typealias Construction = Void
        static 
        func parse(terminal:Terminal) -> Void? 
        {
            switch terminal 
            {
            case    "a" ... "z", 
                    "A" ... "Z",
                    "_", 

                    "\u{00A8}", "\u{00AA}", "\u{00AD}", "\u{00AF}", 
                    "\u{00B2}" ... "\u{00B5}", "\u{00B7}" ... "\u{00BA}",

                    "\u{00BC}" ... "\u{00BE}", "\u{00C0}" ... "\u{00D6}", 
                    "\u{00D8}" ... "\u{00F6}", "\u{00F8}" ... "\u{00FF}",

                    "\u{0100}" ... "\u{02FF}", "\u{0370}" ... "\u{167F}", "\u{1681}" ... "\u{180D}", "\u{180F}" ... "\u{1DBF}", 

                    "\u{1E00}" ... "\u{1FFF}", 

                    "\u{200B}" ... "\u{200D}", "\u{202A}" ... "\u{202E}", "\u{203F}" ... "\u{2040}", "\u{2054}", "\u{2060}" ... "\u{206F}",

                    "\u{2070}" ... "\u{20CF}", "\u{2100}" ... "\u{218F}", "\u{2460}" ... "\u{24FF}", "\u{2776}" ... "\u{2793}",

                    "\u{2C00}" ... "\u{2DFF}", "\u{2E80}" ... "\u{2FFF}",

                    "\u{3004}" ... "\u{3007}", "\u{3021}" ... "\u{302F}", "\u{3031}" ... "\u{303F}", "\u{3040}" ... "\u{D7FF}",

                    "\u{F900}" ... "\u{FD3D}", "\u{FD40}" ... "\u{FDCF}", "\u{FDF0}" ... "\u{FE1F}", "\u{FE30}" ... "\u{FE44}", 

                    "\u{FE47}" ... "\u{FFFD}", 

                    "\u{10000}" ... "\u{1FFFD}", "\u{20000}" ... "\u{2FFFD}", "\u{30000}" ... "\u{3FFFD}", "\u{40000}" ... "\u{4FFFD}", 

                    "\u{50000}" ... "\u{5FFFD}", "\u{60000}" ... "\u{6FFFD}", "\u{70000}" ... "\u{7FFFD}", "\u{80000}" ... "\u{8FFFD}", 

                    "\u{90000}" ... "\u{9FFFD}", "\u{A0000}" ... "\u{AFFFD}", "\u{B0000}" ... "\u{BFFFD}", "\u{C0000}" ... "\u{CFFFD}", 

                    "\u{D0000}" ... "\u{DFFFD}", "\u{E0000}" ... "\u{EFFFD}":
                return ()
            default:
                return nil
            }
        }
    }
    enum IdentifierNext:TerminalRule
    {
        typealias Construction = Void
        static 
        func parse(terminal:Terminal) -> Void?
        {
            switch terminal 
            {
            case    "0" ... "9", 
                    "\u{0300}" ... "\u{036F}", 
                    "\u{1DC0}" ... "\u{1DFF}", 
                    "\u{20D0}" ... "\u{20FF}", 
                    "\u{FE20}" ... "\u{FE2F}":
                return ()
            default:
                return IdentifierFirst.parse(terminal: terminal) 
            }
        }
    }
    //  IdentifierBase ::= IdentifierFirst IdentifierNext *
    enum IdentifierBase:ParsingRule 
    {
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws 
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any 
        {
            try input.parse(as: IdentifierFirst.self)
            input.parse(as: IdentifierNext.self, in: Void.self)
        }
    }
    //  IdentifierLeaf ::= IdentifierBase Arguments ? 
    enum IdentifierLeaf:ParsingRule 
    {
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws 
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any 
        {
            try input.parse(as: IdentifierBase.self)
            input.parse(as: Arguments?.self)
        }
    }
    
    enum DotlessOperatorFirst:TerminalRule 
    {
        typealias Construction = Void
        static 
        func parse(terminal:Terminal) -> Void?
        {
            switch terminal 
            {
            case    "/", "=", "-", "+", "!", "*", "%", "<", ">", "&", "|", "^", "~", "?",
                    "\u{00A1}" ... "\u{00A7}",
                    "\u{00A9}", "\u{00AB}",
                    "\u{00AC}", "\u{00AE}",
                    "\u{00B0}" ... "\u{00B1}",
                    "\u{00B6}", "\u{00BB}", "\u{00BF}", "\u{00D7}", "\u{00F7}",
                    "\u{2016}" ... "\u{2017}",
                    "\u{2020}" ... "\u{2027}",
                    "\u{2030}" ... "\u{203E}",
                    "\u{2041}" ... "\u{2053}",
                    "\u{2055}" ... "\u{205E}",
                    "\u{2190}" ... "\u{23FF}",
                    "\u{2500}" ... "\u{2775}",
                    "\u{2794}" ... "\u{2BFF}",
                    "\u{2E00}" ... "\u{2E7F}",
                    "\u{3001}" ... "\u{3003}",
                    "\u{3008}" ... "\u{3020}",
                    "\u{3030}":
                return ()
            default:
                return nil
            }
        }
    }
    enum DotlessOperatorNext:TerminalRule
    {
        typealias Construction = Void
        static 
        func parse(terminal:Terminal) -> Void?
        {
            switch terminal 
            {
            case    "\u{0300}" ... "\u{036F}",
                    "\u{1DC0}" ... "\u{1DFF}",
                    "\u{20D0}" ... "\u{20FF}",
                    "\u{FE00}" ... "\u{FE0F}",
                    "\u{FE20}" ... "\u{FE2F}",
                    "\u{E0100}" ... "\u{E01EF}":
                return ()
            default:
                return DotlessOperatorFirst.parse(terminal: terminal) 
            }
        }
    }
    //  DotlessOperatorLeaf ::= DotlessOperatorFirst DotlessOperatorNext * Arguments 
    enum DotlessOperatorLeaf:ParsingRule 
    {
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws 
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any 
        {
            try input.parse(as: DotlessOperatorFirst.self)
                input.parse(as: DotlessOperatorNext.self, in: Void.self)
            try input.parse(as: Arguments.self)
        }
    }
    enum DottedOperatorNext:TerminalRule
    {
        typealias Construction = Void
        static 
        func parse(terminal:Terminal) -> Void?
        {
            switch terminal 
            {
            case ".":
                return ()
            default:
                return DotlessOperatorFirst.parse(terminal: terminal) ?? 
                        DotlessOperatorNext.parse(terminal: terminal)
            }
        }
    }
    //  Leaf  ::= IdentifierLeaf
    //          | DotlessOperatorLeaf
    //          | '.' DottedOperatorNext + Arguments 
    enum Leaf:ParsingRule 
    {
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any 
        {
            guard   case nil = input.parse(as: IdentifierLeaf?.self), 
                    case nil = input.parse(as: DotlessOperatorLeaf?.self)
            else 
            {
                return 
            }
            try input.parse(as: Encoding.Period.self)
            try input.parse(as: DottedOperatorNext.self)
                input.parse(as: DottedOperatorNext.self, in: Void.self)
            try input.parse(as: Arguments.self)
        }
    }
    //  LexicalComponent  ::= IdentifierBase   '.' Leaf 
    //                      | IdentifierBase Arguments
    //                      | IdentifierBase ( '-' . * ) ?
    //                      |   '.' IdentifierLeaf
    //                      | ( '.' DottedOperatorNext + Arguments )
    //                      | DotlessOperatorLeaf
    //                      | UInt   '-' UInt   '-' UInt
    //                      | UInt ( '.' UInt ( '.' UInt ( '.' UInt ) ? ) ? ) ?
    enum LexicalPathComponents:ParsingRule
    {
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) 
            throws -> URI.LexicalPath.Segmentation<Location>
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any 
        {
            let start:Location = input.index 
            guard case nil = input.parse(as: IdentifierBase?.self)
            else 
            {
                let end:Location = input.index 
                if let _:Void = input.parse(as: Encoding.Period?.self)
                {
                    //  /foo.bar          -> ['foo', 'bar']
                    //  /foo.bar(baz:)    -> ['foo', 'bar(baz:)']
                    //  /foo.<(_:_:)      -> ['foo',   '<(_:_:)']
                    //  /foo....(_:_:)    -> ['foo', '...(_:_:)']
                    //  note: the leading dot is *not* part of the operator.
                    let next:Location = input.index 
                    try input.parse(as: Leaf.self)
                    return .reveal(big: end, little: next)
                }
                // since the hyphen-based suffix can be empty (and therefore always succeeds)
                else if let _:Void = input.parse(as: Arguments?.self)
                {
                    //  docc compatibility form. it’s exactly the same as prefixing 
                    //  the identifier with a '.', and therefore implies an empty 
                    //  semantic component right before it.
                    //  /bar(baz:) -> ['', 'bar(baz:)']
                    return .little(start)
                }
                else if let _:Void = input.parse(as: Encoding.Hyphen?.self)
                {
                    //  a package name, like '/swift-grammar', or a docc disambiguator
                    //  like '/indices-ckjvzkc' or '/indices-swift.var'.
                    //  after encountering a hyphen, there are no restrictions 
                    //  on what characters can appear through the end of the component.
                    input.parse(as: Terminal.self, in: Void.self)
                    return .opaque(end)
                }
                else 
                {
                    return .big
                }
            }
            guard case nil = input.parse(as: Encoding.Period?.self)
            else
            {
                let next:Location = input.index
                if let _:Void = input.parse(as: IdentifierLeaf?.self)
                {
                    //  /.bar       -> ['', 'bar']
                    //  /.bar(baz:) -> ['', 'bar(baz:)']
                    return .little(next)
                }
                else 
                {
                    //  /...(_:_:)  -> ['', '...(_:_:)']
                    //  note: the leading dot is *part* of the operator, for 
                    //  docc compatibility purposes.
                    try input.parse(as: DottedOperatorNext.self)
                        input.parse(as: DottedOperatorNext.self, in: Void.self)
                    try input.parse(as: Arguments.self)
                    return .little(start)
                }
            }
            guard case nil = input.parse(as: DotlessOperatorLeaf?.self)
            else 
            {
                //  /<(_:_:)  -> ['', '<(_:_:)']
                return .little(start)
            }
            
            let first:Int = try input.parse(as: Integer.self)
            guard case nil = input.parse(as: Encoding.Hyphen?.self)
            else 
            {
                // parse a date 
                let month:Int = try input.parse(as: Integer.self)
                try input.parse(as: Encoding.Hyphen.self)
                let day:Int = try input.parse(as: Integer.self)
                return .version(.date(year: first, month: month, day: day))
            }
            // parse a x.y.z.w semantic version. the w component is 
            // a documentation version, which is a sub-patch increment
            guard let minor:Int = input.parse(as: Integer?.self)
            else 
            {
                return .version(.tag(major: first, nil))
            }
            guard let patch:Int = input.parse(as: Integer?.self)
            else 
            {
                return .version(.tag(major: first, (minor, nil)))
            }
            guard let edition:Int = input.parse(as: Integer?.self)
            else 
            {
                return .version(.tag(major: first, (minor, (patch, nil))))
            }
            return .version(.tag(major: first, (minor, (patch, edition))))
        }
    }
}
// it would be really nice if this were generic over ``ASCIITerminal``
extension URI.Rule where Terminal == UInt8
{
    enum USR:ParsingRule
    {
        enum Synthesized:LiteralRule 
        {
            static 
            var literal:[UInt8] 
            {
                // '::SYNTHESIZED::'
                [
                    0x3a, 0x3a, 
                    0x53, 0x59, 0x4e, 0x54, 0x48, 0x45, 0x53, 0x49, 0x5a, 0x45, 0x44, 
                    0x3a, 0x3a
                ]
            }
        }
        // all name elements can contain a number, including the first
        enum MangledNameElement:TerminalRule  
        {
            typealias Construction  = Void
            static 
            func parse(terminal:UInt8) -> Void?
            {
                switch terminal 
                {
                //    '_'   'A' ... 'Z'    'a' ... 'z'    '0' ... '9',   '@'
                case 0x5f, 0x41 ... 0x5a, 0x61 ... 0x7a, 0x30 ... 0x39, 0x40:
                    return ()
                default: 
                    return nil
                }
            }
        }
        enum MangledName:ParsingRule 
        {
            // Mangled Identifier ::= <Language> ':' ? <Mangled Identifier Head> <Mangled Identifier Next> *
            static 
            func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws -> Symbol.ID
                where Grammar.Parsable<Location, Terminal, Diagnostics>:Any
            {
                guard let language:UInt8    = input.next()
                else 
                {
                    throw Graph.SymbolError.unidentified 
                }
                    input.parse(as: Encoding.Colon?.self)
                let start:Location          = input.index 
                try input.parse(as: MangledNameElement.self)
                    input.parse(as: MangledNameElement.self, in: Void.self)
                let end:Location    = input.index 
                let utf8:[UInt8]    = [UInt8].init(input[start ..< end])
                switch language 
                {
                case 0x73: // 's'
                    return .swift(utf8)
                case 0x63: // 'c'
                    return .c(utf8)
                case let code: 
                    throw Graph.SymbolError.unsupportedLanguage(code: code)
                }
            }
        }
        
        // USR  ::= <Mangled Name> ( '::SYNTHESIZED::' <Mangled Name> ) ?
        static 
        func parse<Diagnostics>(_ input:inout ParsingInput<Diagnostics>) throws -> Symbol.USR
            where Grammar.Parsable<Location, Terminal, Diagnostics>:Any
        {
            let first:Symbol.ID = try input.parse(as: MangledName.self)
            guard let _:Void = input.parse(as: Synthesized?.self)
            else 
            {
                return .natural(first)
            }
            let second:Symbol.ID = try input.parse(as: MangledName.self)
            return .synthesized(from: first, for: second)
        }
    }
}