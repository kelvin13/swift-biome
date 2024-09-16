import SymbolSource 

extension Branch
{
    /// symbol relationships that are independent of, and unaffected by any 
    /// downstream module consumers. 
    /// 
    /// in swift, it is not possible to retroactively subclass class types or 
    /// conform protocols to other protocols, so certain information about a 
    /// symbol can be determined using only information about modules the 
    /// symbol’s culture depends on.
    /// 
    /// the meaning of the roles stored in this structure depends on the kind of 
    /// symbol using it.
    ///
    /// -   callable class members can have a single role if they override 
    ///     a virtual superclass member.
    ///
    /// -   callable protocol members can have one or more upstream protocol 
    ///     requirements that they could serve as a default implementation for.
    ///
    ///     there can be more than one requirement if a type conforms to 
    ///     multiple protocols that have at least one requirement in common.
    ///
    ///     members of concrete types that merely satisfy protocol 
    ///     requirements are not default implementations, because any 
    ///     member of a concrete type can become an implementation 
    ///     via a retroactive protocol conformance.
    /// 
    /// -   protocol requirements can have one or more requirements of upstream 
    ///     protocols they restate. 
    /// 
    ///     there can be more than one such upstream requirement if a protocol 
    ///     refines multiple protocols that declare the same requirement.
    /// 
    /// -   protocols can have requirements, and can also have upstream protocols 
    ///     they refine. both kinds of roles are stored in the same buffer; they 
    ///     can be distinguished by querying the shape of the symbol they reference.
    /// 
    ///     protocol requirements *always* have the same culture as the protocol 
    ///     itself.
    /// 
    ///     note: ``Ecosystem.add(role:to:pinned:)`` relies on this assumption!
    /// 
    /// -   classes can have a single role if they have a superclass.
    /// 
    /// -   other kinds of symbols never have roles.
    enum SymbolRoles:Equatable, Sendable
    {
        case one        (Symbol)
        case many   (Set<Symbol>)
        
        private 
        init?(_ symbols:[Symbol]) 
        {
            if symbols.isEmpty 
            {
                return nil 
            }
            else if symbols.count == 1 
            {
                self = .one(symbols[0])
            }
            else  
            {
                self = .many(.init(symbols))
            }
        }
        init?(_ roles:some Sequence<SurfaceBuilder.Role<Symbol>>, 
            superclass:Symbol?, 
            scope:Symbol.Scope?, 
            as shape:Shape) 
        {
            if  let superclass:Symbol = superclass 
            {
                switch  (shape, scope)
                {
                case    (.class, .member(of: _)?), 
                        (.class,           nil):
                    self = .one(superclass)
                
                default: 
                    // should have thrown a ``ColorError`` earlier
                    fatalError("unreachable")
                }
                for _:SurfaceBuilder.Role<Symbol> in roles 
                {
                    fatalError("unreachable")
                }
            }
            else 
            {
                switch  (shape, scope)
                {
                case    (.callable(_),      .requirement(of: _)?), 
                        (.associatedtype,   .requirement(of: _)?):
                    self.init(roles.map 
                    {
                        switch $0 
                        {
                        case .override(of: let upstream): 
                            return upstream
                        default:
                            fatalError("requirements cannot be default implementations")
                            // throw PoliticalError.conflict(is: .requirement(of: interface), 
                            //     and: other)
                        }
                    })
                
                case    (_,                 .requirement(of: _)?):
                    // should have thrown a ``ColorError`` earlier
                    fatalError("unreachable")
                    
                case    (.concretetype(_),  nil), 
                        (.typealias,          _), 
                        (.global(_),        nil):
                    for _:SurfaceBuilder.Role<Symbol> in roles
                    {
                        fatalError("unreachable") 
                    }
                    return nil
                
                case    (.concretetype(_),  .member(of: _)?), 
                        (.callable(_),      .member(of: _)?):
                    self.init(roles.map 
                    {
                        switch $0 
                        {
                        case .override(of: let upstream), .implementation(of: let upstream): 
                            return upstream
                        default: 
                            fatalError("unreachable") 
                        }
                    })
                    
                case    (.callable(_),      nil):
                    self.init(roles.map 
                    {
                        switch $0 
                        {
                        case .implementation(of: let upstream): 
                            return upstream
                        default: 
                            fatalError("unreachable")
                        }
                    })
                    
                case    (.protocol,         nil):
                    self.init(roles.map
                    {
                        switch $0
                        {
                        case .interface(of: let symbol), .refinement(of: let symbol):
                            return symbol 
                        default: 
                            fatalError("unreachable") 
                        }
                    })
                
                default: 
                    fatalError("unreachable")
                }
            }
        }
    }
}

extension Branch.SymbolRoles:Sequence  
{
    func map<T>(_ transform:(Symbol) throws -> T) rethrows -> [T]
    {
        switch self 
        {
        case .one(let symbol): 
            return [try transform(symbol)]
        case .many(let symbols): 
            return try symbols.map(transform)
        }
    }
    func makeIterator() -> Set<Symbol>.Iterator 
    {
        switch self 
        {
        case .one(let symbol): 
            return ([symbol] as Set<Symbol>).makeIterator()
        case .many(let symbols): 
            return symbols.makeIterator()
        }
    }
}