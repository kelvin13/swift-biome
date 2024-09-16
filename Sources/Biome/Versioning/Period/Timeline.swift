import Sediment

struct Timeline<Trunk>:Sequence, IteratorProtocol where Trunk:FieldViews
{
    private 
    var trunk:Trunk.Iterator? 
    private 
    let field:FieldAccessor<Trunk.Axis.Divergence, Trunk.Value>
    
    init(_ trunk:__shared Trunk, field:FieldAccessor<Trunk.Axis.Divergence, Trunk.Value>)
    {
        self.trunk = trunk.makeIterator()
        self.field = field
    }

    mutating 
    func next() -> FieldValues?
    {
        guard let view:Period<Trunk.Axis>.FieldView<Trunk.Value> = self.trunk?.next() 
        else 
        {
            return nil 
        }

        let index:Sediment<Version.Revision, Trunk.Value>.Index?
        switch view.axis[self.field]
        {
        case .original(let head):
            // we know no prior epochs could possibly contain any information 
            // about this symbol, so we can stop iterating after this.
            self.trunk = nil

            if  let head:OriginalHead<Trunk.Value>
            {
                index = view.sediment[head].find(view.latest.revision)
            }
            else 
            {
                index = nil
            }
        
        case .alternate(let alternate?):
            if  view.latest.revision < alternate.since 
            {
                index = nil
            }
            else 
            {
                index = view.sediment[alternate.head].find(view.latest.revision)
                assert(index != nil, "containment check succeeded but revision was not found")
            }

        case .alternate(nil):
            index = nil
        }
        return .init(.init(current: index, sediment: view.sediment), 
            latest: view.latest,
            fork: view.fork)
    }
}
extension Timeline
{
    struct FieldValues:Sequence
    {
        private 
        let iterator:Sediment<Version.Revision, Trunk.Value>.StratumIterator
        let latest:Version
        /// The branch and revision this period was forked from, 
        /// if applicable.
        let fork:Version?

        init(_ iterator:Sediment<Version.Revision, Trunk.Value>.StratumIterator, 
            latest:Version,
            fork:Version?)
        {
            self.iterator = iterator
            self.latest = latest
            self.fork = fork
        }

        func makeIterator() -> Sediment<Version.Revision, Trunk.Value>.StratumIterator
        {
            self.iterator
        }

        func version(before revision:Version.Revision) -> Version?
        {
            revision.predecessor.map { .init(self.latest.branch, $0) } ?? self.fork
        }
    }
}