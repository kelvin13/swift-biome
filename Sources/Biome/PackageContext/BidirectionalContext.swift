struct BidirectionalContext:AnisotropicContext, Sendable
{
    struct Consumer 
    {
        let pinned:Tree.Pinned 
        let modules:Set<Module>

        var nationality:Package 
        {
            self.pinned.nationality
        }
    }

    private(set)
    var dependencies:[Tree.Pinned],
        consumers:[Consumer]
    private(set)
    var foreign:[Package: Tree.Pinned]
    let local:Tree.Pinned 
    
    init(local:Tree.Pinned, context:__shared Trees) 
    {
        let revision:Branch.Revision = local.revision
        self.local = local
        self.foreign = .init(minimumCapacity: revision.pins.count)
        self.dependencies = []
        for (index, version):(Package, Version) in revision.pins 
        {
            let dependency:Tree.Pinned = .init(context[index], version: version)
            self.dependencies.append(dependency)
            self.foreign[index] = dependency
        }
        self.consumers = []
        for (index, versions):(Package, [Version: Set<Module>]) in 
            revision.consumers
        {
            let consumer:Tree = context[index]
            if  let version:Version = consumer.default, 
                let modules:Set<Module> = versions[version], 
                self.local.tree.settings.whitelist?.contains(consumer.id) ?? true 
            {
                let consumer:Tree.Pinned = .init(consumer, version: version)
                self.consumers.append(.init(pinned: consumer, modules: modules))
                self.foreign[index] = consumer
            }
        }
    }
}
