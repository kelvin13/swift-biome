import Notebook 
import SymbolAvailability
import SymbolSource

extension Declaration:Sendable where Target:Sendable {}
extension Declaration:Equatable where Target:Equatable {}

@frozen public
struct Declaration<Target>
{
    // signatures and declarations can change without disturbing the symbol identifier, 
    // since they contain information that is not part of ABI.
    public 
    let fragments:Notebook<Highlight, Target>
    public 
    let signature:Notebook<Highlight, Never>
    public 
    let availability:Availability
    // these *might* be version-independent, but right now we are storing generic 
    // parameter/associatedtype names
    public 
    let extensionConstraints:[Generic.Constraint<Target>]
    public 
    let genericConstraints:[Generic.Constraint<Target>]
    // generic parameter *names* are not part of ABI.
    public 
    let generics:[Generic]

    @inlinable public 
    init(fragments:Notebook<Highlight, Target>, 
        signature:Notebook<Highlight, Never>,
        availability:Availability = .init(),
        extensionConstraints:[Generic.Constraint<Target>] = [],
        genericConstraints:[Generic.Constraint<Target>] = [],
        generics:[Generic] = [])
    {
        self.fragments = fragments
        self.signature = signature
        self.availability = availability
        self.extensionConstraints = extensionConstraints
        self.genericConstraints = genericConstraints
        self.generics = generics
    }
    @inlinable public 
    init(fallback:String) 
    {
        let fallback:CollectionOfOne<(String, Highlight)> = 
            .init((fallback, .text))
        self.init(fragments: .init(), signature: .init(fallback))
    }

    func forEachTarget(_ body:(Target) throws -> ()) rethrows 
    {
        for (_, target):(_, Target) in self.fragments.links 
        {
            try body(target)
        }
        for constraint:Generic.Constraint<Target> in self.extensionConstraints 
        {
            try constraint.forEach(body)
        }
        for constraint:Generic.Constraint<Target> in self.genericConstraints 
        {
            try constraint.forEach(body)
        }
    }
    @inlinable public 
    func map<T>(_ transform:(Target) throws -> T) rethrows -> Declaration<T>
    {
        .init(fragments: try self.fragments.map(transform), 
            signature: self.signature, 
            availability: self.availability, 
            extensionConstraints: try self.extensionConstraints.map 
            {
                try $0.map(transform)
            },
            genericConstraints: try self.genericConstraints.map 
            {
                try $0.map(transform)
            }, 
            generics: self.generics)
    }
    @inlinable public 
    func flatMap<T>(_ transform:(Target) throws -> T?) rethrows -> Declaration<T>
    {
        .init(fragments: try self.fragments.compactMap(transform), 
            signature: self.signature, 
            availability: self.availability, 
            extensionConstraints: try self.extensionConstraints.map 
            {
                try $0.flatMap(transform)
            },
            genericConstraints: try self.genericConstraints.map 
            {
                try $0.flatMap(transform)
            }, 
            generics: self.generics)
    }
}
