import Grammar 

extension SymbolIdentifier 
{
    @inlinable public 
    init<UTF8>(parsing utf8:UTF8) throws where UTF8:Collection<UInt8>
    {
        self = try Rule<UTF8.Index>.parse(utf8)
    }

    @inlinable public 
    var interface:(culture:ModuleIdentifier, protocol:(name:String, id:Self))?
    {
        // if a vertex is non-canonical, the symbol id of its generic base 
        // always starts with a mangled protocol name. 
        // note that our demangling implementation cannot handle “known” 
        // protocols like 'Swift.Equatable'. but this is fine because we 
        // are only using this to detect symbols that are defined in extensions 
        // on underscored protocols.
        var input:ParsingInput<NoDiagnostics> = .init(self.string.utf8)
        guard case let (namespace, name)? = 
            input.parse(as: Rule<String.Index>.MangledProtocolName?.self)
        else 
        {
            return nil 
        }
        // parsing input shares indices with `self.string`. we can use the 
        // unsafe `init(unchecked:)` because `USR.Rule.MangledProtocolName` 
        // only succeeds if the first character is a lowercase 's'
        let id:Self = .init(unchecked: .init(self.string[..<input.index]))
        let culture:ModuleIdentifier = 
            input.parse(as: Rule<String.Index>.MangledExtensionContext?.self) ?? namespace
        return (culture, (name, id))
    }
}
extension SymbolIdentifier 
{
    /// A rule matching a mangled symbol name, including the language prefix and 
    /// an optional colon separator.
    public
    enum Rule<Location>
    {
        public 
        typealias Terminal = UInt8
        public 
        typealias Encoding = UnicodeEncoding<Location, Terminal>
    }
}
extension SymbolIdentifier.Rule:ParsingRule
{
    @inlinable public static 
    func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
        throws -> SymbolIdentifier
        where Source:Collection<UInt8>, Source.Index == Location
    {
        let language:SymbolIdentifier.Language = try input.parse(as: Language.self)
        
        input.parse(as: Encoding.Colon?.self)
        
        let start:Location = input.index 
        try input.parse(as: MangledNameElement.self)
            input.parse(as: MangledNameElement.self, in: Void.self)
        let end:Location = input.index 
        
        return .init(language, input[start ..< end])
    }

    /// A rule matching a language prefix; either [`'c'`]() or [`'s'`]() (for “swift”).
    public 
    enum Language:TerminalRule  
    {
        public 
        typealias Terminal = UInt8
        public 
        typealias Construction = SymbolIdentifier.Language
        
        @inlinable public static 
        func parse(terminal:UInt8) -> SymbolIdentifier.Language?
        {
            switch terminal 
            {
            case 0x73: // 's'
                return .swift
            case 0x63: // 'c'
                return .c
            default: 
                return nil
            }
        }
    }
    /// A rule matching a character that is allowed to appear in a mangled name. 
    /// 
    /// This rule accepts the classes [`'_'`](), [`'A' ... 'Z'`](), [`'a' ... 'z'`](), 
    /// [`'0' ... '9'`](), and [`'@'`]().
    public 
    enum MangledNameElement:TerminalRule  
    {
        public 
        typealias Terminal = UInt8
        public 
        typealias Construction  = Void

        @inlinable public static 
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
}
extension SymbolIdentifier.Rule 
{
    // example 1: 'ss8_PointerPsE11predecessorxyF'
    // 
    // 's': language is swift 
    // 's': namespace is 'Swift'
    // '8_PointerP': protocol ('P') is '_Pointer', which is 8 characters long
    // 'sE': perpetrator is 'Swift'
    
    // example 2: 's3Foo4_BarP3BazE'
    // 
    // 's': language is swift 
    // '3Foo': namespace is 'Foo'
    // '4_BarP': protocol ('P') is '_Bar', which is 4 characters long
    // '3BazE': perpetrator is 'Baz'
    // 
    // note that there would usually be more characters after this prefix.
    
    // never contains substitutions
    public
    enum MangledIdentifier:ParsingRule
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> String
            where Source:Collection<UInt8>, Source.Index == Location
        {
            // cannot begin with a '0', since that signifies that substitutions will occur
            let count:Int = try input.parse(as: Pattern.UnsignedNormalizedInteger<
                UnicodeDigit<Location, Terminal, Int>.Natural, 
                UnicodeDigit<Location, Terminal, Int>.Decimal>.self)
            // FIXME: properly handle punycode
            return String.init(decoding: try input.parse(prefix: count), as: Unicode.ASCII.self)
        }
    }
    public 
    enum MangledModuleName:ParsingRule
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> ModuleIdentifier
            where Source:Collection<UInt8>, Source.Index == Location
        {
            if let _:Void = input.parse(as: Encoding.S.Lowercase?.self)
            {
                return "Swift"
            }
            else 
            {
                return .init(try input.parse(as: MangledIdentifier.self))
            }
        }
    }
    public 
    enum MangledProtocolName:ParsingRule
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> (module:ModuleIdentifier, name:String)
            where Source:Collection<UInt8>, Source.Index == Location
        {
            try input.parse(as: Encoding.S.Lowercase.self)
            let module:ModuleIdentifier = try input.parse(as: MangledModuleName.self)
            let name:String = try input.parse(as: MangledIdentifier.self)
            try input.parse(as: Encoding.P.Uppercase.self)
            return (module, name)
        }
    }
    public 
    enum MangledExtensionContext:ParsingRule
    {
        public 
        typealias Terminal = UInt8

        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> ModuleIdentifier
            where Source:Collection<UInt8>, Source.Index == Location
        {
            let culture:ModuleIdentifier = try input.parse(as: MangledModuleName.self)
            try input.parse(as: Encoding.E.Uppercase.self)
            return culture
        }
    }
}