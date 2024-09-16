// this isn’t *quite* ``SurfaceBuilder.Context``, because ``local`` is pinned here.
struct DirectionalContext:AnisotropicContext, Sendable 
{
    private(set) 
    var foreign:[Package: Tree.Pinned]
    let local:Tree.Pinned 

    init(local:Tree.Pinned, upstream:[Package: Tree.Pinned])
    {
        self.foreign = upstream 
        self.local = local
    }
    init(local:Tree.Pinned, pins:__shared [Package: Version], 
        context:__shared Trees)
    {
        self.local = local 
        self.foreign = .init(minimumCapacity: pins.count)
        for (index, version):(Package, Version) in pins 
        {
            self.foreign[index] = .init(context[index], version: version)
        }
    }
}

extension DirectionalContext 
{
    init(local:Tree.Pinned, context:__shared Trees) 
    {
        self.init(local: local, pins: local.revision.pins, context: context)
    }
    init(local:Tree.Pinned, metadata:__shared Module.Metadata, context:__shared Trees) 
    {
        let filter:Set<Package> = .init(metadata.dependencies.lazy.map(\.nationality))
        self.init(local: local, 
            pins: local.revision.pins.filter { filter.contains($0.key) }, 
            context: context)
    }
}
extension DirectionalContext 
{
    func repinned(to version:Version, context:__shared Trees) -> Self 
    {
        .init(local: self.local.repinned(to: version), context: context)
    }
}