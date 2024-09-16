import Grammar 

extension Toolchain 
{
    @inlinable public 
    init(parsing string:some StringProtocol) throws 
    {
        self = try Rule<String.Index>.parse(string.unicodeScalars)
    }
}
extension Toolchain 
{
    public 
    struct Rule<Location>:ParsingRule
    {
        public 
        typealias Terminal = Unicode.Scalar
        public 
        typealias Encoding = UnicodeEncoding<Location, Terminal>
        
        public 
        enum Swift:LiteralRule 
        {
            public
            typealias Terminal = Unicode.Scalar
            
            @inlinable public static
            var literal:String.UnicodeScalarView 
            {
                "swift".unicodeScalars
            }
        }
        public 
        enum Release:LiteralRule 
        {
            public
            typealias Terminal = Unicode.Scalar
            
            @inlinable public static
            var literal:String.UnicodeScalarView 
            {
                "RELEASE".unicodeScalars
            }
        }
        public 
        enum DevelopmentSnapshot:LiteralRule 
        {
            public
            typealias Terminal = Unicode.Scalar
            
            @inlinable public static
            var literal:String.UnicodeScalarView 
            {
                "DEVELOPMENT-SNAPSHOT".unicodeScalars
            }
        }
    
        @inlinable public static 
        func parse<Source>(_ input:inout ParsingInput<some ParsingDiagnostics<Source>>) 
            throws -> Toolchain
            where Source:Collection<Unicode.Scalar>, Source.Index == Location
        {
            try input.parse(as: Swift.self)
            try input.parse(as: Encoding.Hyphen.self)
            if case _? = input.parse(as: DevelopmentSnapshot?.self)
            {
                try input.parse(as: Encoding.Hyphen.self)
                return .nightly(try input.parse(as: Date.Rule<Location>.self))
            }
            else 
            {
                let semantic:SemanticVersion.Masked = 
                    try input.parse(as: SemanticVersion.Rule<Location>.Masked.self)
                try input.parse(as: Encoding.Hyphen.self)
                try input.parse(as: Release.self)
                return .release(semantic)
            }
        }
    }
}