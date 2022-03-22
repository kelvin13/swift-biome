import StructuredDocument 
import HTML

extension Documentation 
{
    enum UnresolvedLink:Hashable, CustomStringConvertible, Sendable
    {
        enum Disambiguator 
        {
            enum DocC:Hashable, CustomStringConvertible 
            {
                case kind(Biome.Symbol.Kind)
                case hash(String)
                
                init(_ string:String)
                {
                    self = Biome.Symbol.Kind.init(rawValue: string).map(Self.kind(_:)) ?? .hash(string)
                }
                
                var description:String 
                {
                    switch self 
                    {
                    case .kind(let kind):   return "(\(kind.rawValue))"
                    case .hash(let hash):   return "(hash: \(hash))"
                    }
                }
            }
        }
        
        case preresolved(ResolvedLink)
        case docc(doc:[[UInt8]], Disambiguator.DocC?)

        static 
        func docc<S>(normalizing string:S) -> Self 
            where S:StringProtocol, S.SubSequence == Substring
        {
            let path:Substring, 
                suffix:Disambiguator.DocC?
            if let hyphen:String.Index = string.firstIndex(of: "-") 
            {
                path    = string[..<hyphen]
                suffix  = .init(String.init(string[string.index(after: hyphen)...]))
            }
            else 
            {
                path    = string[...]
                suffix  = nil
            }
            // split on slashes
            return .docc(doc: URI.normalize(path: path.utf8.split(separator: 0x2f)), suffix)
        }
        
        var description:String 
        {
            switch self 
            {
            case .preresolved(let resolved):
                return "preresolved (\(resolved))"
            case .docc(doc: let path, let suffix?):
                return "\(String.init(decoding: URI.concatenate(normalized: path), as: Unicode.UTF8.self)) \(suffix)"
            case .docc(doc: let path, nil):
                return    String.init(decoding: URI.concatenate(normalized: path), as: Unicode.UTF8.self)
            }
        }
    }
    enum ResolvedLink:Hashable, Sendable
    {
        case article(Int)
        case module(Int)
        case symbol(Int, victim:Int?)
    }

    enum Format 
    {
        /// entrapta format 
        case entrapta
        
        /// lorentey’s `swift-collections` format
        // case collections
        
        /// nate cook’s `swift-algorithms` format
        // case algorithms 
        
        /// apple’s DocC format
        case docc
    }
    struct UnresolvedLinkContext 
    {
        let namespace:Int 
        var scope:[[UInt8]]
    }
    enum ArticleTitle
    {
        case free(title:String)
        case owned(by:ResolvedLink)
    }
    struct ArticleContent<Anchor> where Anchor:Hashable 
    {
        typealias Element = HTML.Element<Anchor> 
        
        let errors:[Error]
        let summary:DocumentTemplate<Anchor, [UInt8]>?
        let discussion:DocumentTemplate<Anchor, [UInt8]>?
        
        static 
        var empty:Self 
        {
            .init(errors: [], summary: nil, discussion: nil)
        }
        
        func compactMapAnchors<T>(_ transform:(Anchor) throws -> T?) rethrows -> ArticleContent<T> 
            where T:Hashable
        {
            .init(errors:   self.errors, 
                summary:    try self.summary?.compactMap(transform), 
                discussion: try self.discussion?.compactMap(transform))
        }
    }
    /* enum ArticleOwner 
    {
        case free(title:String)
        case module(summary:Article<UnresolvedLink>.Element?, index:Int)
        case symbol(summary:Article<UnresolvedLink>.Element?, index:Int) 
    } */
    struct Article<Anchor> where Anchor:Hashable
    {
        typealias Element = HTML.Element<Anchor> 
        
        let title:String
        let stem:[[UInt8]]
        let content:ArticleContent<Anchor>
        let context:UnresolvedLinkContext
        /* 
        init(namespace:Int, path:[[UInt8]], title:String, content:DocumentTemplate<Anchor, [UInt8]>)
        {
            self.namespace = namespace
            self.path = path
            self.title = title
            self.content = content
        }
        init<S>(namespace:Int, path:S, title:String, content:[Element])
            where S:Sequence, S.Element:StringProtocol
        {
            self.namespace  = namespace
            self.path       = path.map{ URI.encode(component: $0.utf8) }
            self.title      = title
            self.content    = .init(freezing: content)
        } */

    }
}
extension Documentation.ArticleContent where Anchor == Documentation.UnresolvedLink
{    
    init(errors:[Error], summary:Element?, discussion:[Element]) 
    {
        self.errors = errors
        self.summary = summary.map(DocumentTemplate<Anchor, [UInt8]>.init(freezing:))
        self.discussion = discussion.isEmpty ? nil : .init(freezing: discussion)
    }
}
