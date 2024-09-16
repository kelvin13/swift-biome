import SymbolSource 

extension _SymbolLink
{
    // warning: do not make ``Equatable``, unless we enforce the correctness 
    // of the `hyphen` field!
    struct Component 
    {
        private(set)
        var string:String 
        private(set)
        var hyphen:String.Index?

        init(_ string:String, hyphen:String.Index? = nil)
        {
            self.string = string 
            self.hyphen = hyphen
        }

        mutating 
        func removeDocCFragment(global:Bool) -> Disambiguator.DocC?
        {
            guard let hyphen:String.Index = self.hyphen
            else 
            {
                return nil 
            }

            let text:Substring = self.string[self.string.index(after: hyphen)...]
            let disambiguator:Disambiguator.DocC?
            // will never collide with symbol shapes, since they always contain 
            // a period ('.')
            // https://github.com/apple/swift-docc/blob/d94139a5e64e9ecf158214b1cded2a2880fc1b02/Sources/SwiftDocC/Utility/FoundationExtensions/String%2BHashing.swift
            if let hash:UInt32 = .init(text, radix: 36)
            {
                disambiguator = .fnv(hash: hash)
            }
            else if let shape:Shape = .init(declarationKind: text, global: global)
            {
                disambiguator = .shape(shape)
            }
            else 
            {
                disambiguator = nil
            }
            if case _? = disambiguator 
            {
                self.string = .init(self.string[..<hyphen])
                self.hyphen = nil 
            }
            return disambiguator
        }
    }
}