struct Overlay
{
    var metadata:AlternateHead<Metadata?>?

    init() 
    {
        self.metadata = nil
    }

    var isEmpty:Bool
    {
        if case nil = self.metadata
        {
            return true
        }
        else 
        {
            return false
        }
    }
}
extension Overlay:BranchDivergence
{
    typealias Key = Diacritic
    
    // isomorphic to ``Never``, its fields are only defined so that 
    // keypaths can be constructed to them.
    struct Base
    {
        var metadata:OriginalHead<Metadata?>?
        {
            get { nil }
            set {     }
        }
    }

    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.metadata.revert(to: rollbacks.metadata.overlays)
    }
}
extension Overlay.Base:BranchDivergenceBase
{
    mutating
    func revert(to rollbacks:History.Rollbacks)
    {
        self.metadata.revert(to: rollbacks.metadata.overlays)
    }
}