protocol BranchDivergenceBase
{
    mutating
    func revert(to rollbacks:History.Rollbacks)
}
protocol BranchDivergence<Key>:BranchDivergenceBase
{
    associatedtype Base:BranchDivergenceBase
    associatedtype Key

    init()

    var isEmpty:Bool { get }
}
extension BranchDivergence
{
    fileprivate
    func reverted(to rollbacks:History.Rollbacks) -> Self?
    {
        var reverted:Self = self
            reverted.revert(to: rollbacks)
        return reverted.isEmpty ? nil : reverted
    }
}
extension Dictionary where Value:BranchDivergence
{
    mutating 
    func revert(to rollbacks:History.Rollbacks)
    {
        self = self.compactMapValues { $0.reverted(to: rollbacks) }
    }
}
