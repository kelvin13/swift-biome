extension Biome 
{    
    public 
    struct Module:Identifiable, Sendable
    {
        public
        struct ID:Hashable, Sendable
        {
            let string:String 
            
            // TODO: migrate off of String
            init(_ _utf8:[UInt8]) 
            {
                self.init(String.init(decoding: _utf8, as: Unicode.UTF8.self))
            }
            
            init<S>(_ string:S) where S:StringProtocol 
            {
                self.string = .init(string)
            }
            
            var title:Substring 
            {
                self.string.drop { $0 == "_" } 
            }
            
            func graphIdentifier(bystander:Self?) -> String
            {
                bystander.map { "\(self.string)@\($0.string)" } ?? self.string
            }
        }
        
        public 
        let id:ID
        public 
        let package:Int
        
        let symbols:(core:Range<Int>, extensions:[(bystander:Int, symbols:Range<Int>)])
        var toplevel:[Int]
        
        var title:String 
        {
            .init(self.id.title)
        }
        var allSymbols:FlattenSequence<[Range<Int>]>
        {
            ([self.symbols.core] + self.symbols.extensions.map(\.symbols)).joined()
        }
        
        init(id:ID, package:Int, core:Range<Int>, extensions:[(bystander:Int, symbols:Range<Int>)])
        {
            self.id         = id 
            self.package    = package
            self.symbols    = (core, extensions)
            self.toplevel   = []
        }
    }
    
    /* public 
    struct Graph:Hashable, Sendable 
    {
        var module:Module.ID, 
            bystander:Module.ID?
        
        var namespace:Module.ID 
        {
            self.bystander ?? self.module 
        }
    } */
}
