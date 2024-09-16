import SymbolSource

extension SymbolGraph.Edge:Sendable where Target:Sendable {}
extension SymbolGraph.Edge:Hashable where Target:Hashable {}
extension SymbolGraph.Edge:Equatable where Target:Equatable {}

extension SymbolGraph.Edge.Relation:Sendable where Target:Sendable {}
extension SymbolGraph.Edge.Relation:Hashable where Target:Hashable {}
extension SymbolGraph.Edge.Relation:Equatable where Target:Equatable {}

extension SymbolGraph 
{
    @frozen public 
    struct Edge<Target>
    {
        @frozen public 
        enum Relation 
        {
            case feature
            case member
            case conformer([Generic.Constraint<Target>])
            case subclass
            case override
            case requirement
            case optionalRequirement
            case defaultImplementation

            func forEachTarget(_ body:(Target) throws -> ()) rethrows 
            {
                if case .conformer(let constraints) = self 
                {
                    for constraint:Generic.Constraint<Target> in constraints 
                    {
                        try constraint.forEach(body)
                    }
                }
            }
            @inlinable public
            func map<T>(_ transform:(Target) throws -> T) rethrows -> Edge<T>.Relation
            {
                switch self  
                {
                case .feature:
                    return .feature
                case .member:
                    return .member
                case .conformer(let constraints):
                    return .conformer(try constraints.map { try $0.map(transform) })
                case .subclass:
                    return .subclass
                case .override:
                    return .override
                case .requirement:
                    return .requirement
                case .optionalRequirement:
                    return .optionalRequirement
                case .defaultImplementation:
                    return .defaultImplementation
                }
            }
        }

        public 
        let source:Target 
        public 
        let relation:Relation
        public 
        let target:Target
        
        @inlinable public
        init(_ source:Target, is relation:Relation, of target:Target)
        {
            self.source = source 
            self.relation = relation 
            self.target = target
        }

        @inlinable public
        func map<T>(_ transform:(Target) throws -> T) rethrows -> Edge<T>
        {
            .init(try transform(self.source), 
                is: try self.relation.map(transform), 
                of: try transform(self.target))
        }
        func forEachTarget(_ body:(Target) throws -> ()) rethrows 
        {
            try body(self.source)
            try body(self.target)
            try self.relation.forEachTarget(body)
        }
    }
}
