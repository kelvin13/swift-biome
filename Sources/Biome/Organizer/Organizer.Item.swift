import HTML
import SymbolSource

extension Organizer 
{
    struct Unconditional:HTMLConvertible
    {
        var htmls:EmptyCollection<HTML.Element<Never>>
        {
            .init()
        }
    }
    struct Conditional:HTMLConvertible
    {
        let constraints:[Generic.Constraint<String>]

        init(_ constraints:[Generic.Constraint<String>])
        {
            self.constraints = constraints
        }

        init(_ constraints:[Generic.Constraint<Symbol>], 
            context:__shared some PackageContext, 
            cache:inout ReferenceCache) throws
        {
            self.init(try constraints.map 
            {
                try $0.map { try cache.load($0, context: context).uri }
            })
        }

        var htmls:[HTML.Element<Never>]
        {
            self.constraints.html 
        }
    }

    struct Item<Conditions> 
    {
        // the displayed symbol and uri are not necessarily the same symbol
        let conditions:Conditions
        let display:Symbol.Intrinsic.Display
        let uri:String 

        private 
        init(where conditions:Conditions, display:Symbol.Intrinsic.Display, uri:String)
        {
            self.conditions = conditions
            self.display = display
            self.uri = uri
        }
    }
}
extension Organizer.Item
{
    private 
    init(_ symbol:SymbolReference, 
        where conditions:Conditions, 
        context:__shared some PackageContext, 
        cache:inout ReferenceCache) throws
    {
        let display:Symbol.Intrinsic.Display 
        switch symbol.shape 
        {
        case .associatedtype, .callable(_):
            guard let scope:AtomicPosition<Symbol> = symbol.scope?.target 
            else 
            {
                fallthrough
            }
            display = try cache.load(scope, context: context).display
        default: 
            display = symbol.display
        }
        self.init(where: conditions, display: display, uri: symbol.uri)
    }
}
extension Organizer.Item<Organizer.Unconditional>
{
    init(_ symbol:SymbolReference, 
        context:__shared some PackageContext, 
        cache:inout ReferenceCache) throws
    {
        try self.init(symbol, where: .init(), context: context, cache: &cache)
    }
    init(_ symbol:Symbol, 
        context:__shared some PackageContext, 
        cache:inout ReferenceCache) throws
    {
        try self.init(try cache.load(symbol, context: context), where: .init(), 
            context: context, 
            cache: &cache)
    }
}
extension Organizer.Item<Organizer.Conditional>
{
    init(_ symbol:Symbol, 
        where constraints:[Generic.Constraint<Symbol>], 
        context:__shared some PackageContext, 
        cache:inout ReferenceCache) throws
    {
        try self.init(try cache.load(symbol, context: context), 
            where: .init(constraints, context: context, cache: &cache), 
            context: context, 
            cache: &cache)
    }
}
extension Organizer.Item
{
    static 
    func |<| (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.display.path |<| rhs.display.path
    }
}


extension Organizer.Item:HTMLElementConvertible, HTMLConvertible 
    where Conditions:HTMLConvertible
{
    var html:HTML.Element<Never>
    {
        let signature:HTML.Element<Never> = .a(.code(self.display.path.html), 
            attributes: [.href(self.uri), .class("signature")])
        let conditions:Conditions.RenderedHTML = self.conditions.htmls 
        return conditions.isEmpty ?
            .li(signature) : 
            .li(signature, .p([.init(escaped: "When ")] + conditions))
    }
}

extension Path 
{
    var html:[HTML.Element<Never>]
    {
        var components:[HTML.Element<Never>] = []
            components.reserveCapacity(2 * self.count - 1)
        for component:String in self.prefix
        {
            components.append(.highlight(component, .identifier))
            components.append(.highlight(escaped: ".", .text))
        }
        components.append(.highlight(self.last, .identifier))
        return components
    }
}

extension BidirectionalCollection<Generic.Constraint<String>> 
{
    var html:[HTML.Element<Never>]
    {
        var reversed:ReversedCollection<Self.Indices>.Iterator = 
            self.indices.reversed().makeIterator()

        guard let ultimate:Index = reversed.next()
        else 
        {
            return []
        }
        guard let penultimate:Index = reversed.next()
        else 
        {
            return self[ultimate].html
        }

        guard let partition:Index = reversed.next() 
        else 
        {
            return self[penultimate].html + [.init(escaped: " and ")] + self[ultimate].html 
        }

        var elements:[HTML.Element<Never>] = []
        for constraint:Generic.Constraint<String> in self.prefix(through: partition)
        {
            elements.append(contentsOf: constraint.html)
            elements.append(.init(escaped: ", "))
        }
        elements.append(contentsOf: self[penultimate].html)
        elements.append(.init(escaped: ", and "))
        elements.append(contentsOf: self[ultimate].html)
        
        return elements
    }
}
extension Generic.Constraint<String> 
{
    var html:[HTML.Element<Never>] 
    {
        let verb:String
        switch self.verb
        {
        case .subclasses: 
            verb = " inherits from "
        case .implements:
            verb = " conforms to "
        case .is:
            verb = " is "
        }
        let subject:HTML.Element<Never> = .code(.highlight(self.subject, .type))
        let object:HTML.Element<Never> = .code(.highlight(self.object, .type, uri: self.target))
        return [subject, .init(escaped: verb), object]
    }
}