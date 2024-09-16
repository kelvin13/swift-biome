extension SymbolGraph.Hint:Sendable where Target:Sendable {}
extension SymbolGraph.Hint:Hashable where Target:Hashable {}
extension SymbolGraph.Hint:Equatable where Target:Equatable {}

extension SymbolGraph 
{
    struct Hint<Target>
    {
        let source:Target 
        let origin:Target

        func map<T>(_ transform:(Target) throws -> T) rethrows -> Hint<T>
        {
            .init(source: try transform(self.source), 
                origin: try transform(self.origin))
        }
        func forEachTarget(_ body:(Target) throws -> ()) rethrows 
        {
            try body(self.source)
            try body(self.origin)
        }
    }
}