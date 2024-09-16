import PackageResolution
import SymbolGraphs
import SymbolSource

enum DependencyNotFoundError:Error 
{
    case package                                       (PackageIdentifier)
    case pin                                           (PackageIdentifier)
    case version                        ((Tag, String), PackageIdentifier)
    case module (ModuleIdentifier, (Branch.ID, String), PackageIdentifier)
    case target (ModuleIdentifier,  Branch.ID)
}

struct PackageUpdateContext 
{
    let local:Fasces 
    private
    var storage:[BasisElement]
    
    init(resolution:PackageResolution,
        nationality:Package,
        branch:Version.Branch,
        graph:__shared SymbolGraph,
        trees:inout Trees) throws
    {
        let linkable:[Package: PackageUpdateContext.Dependency] = 
            trees.find(pins: resolution.pins.values)
        
        self.local = trees[nationality].fasces(upTo: branch)
        self.storage = []
        self.storage.reserveCapacity(graph.cultures.count)
        
        for culture:SymbolGraph.Culture in graph.cultures
        {
            let module:AtomicPosition<Module> = 
                trees[nationality][branch].addModule(culture.id,
                    nationality: nationality, 
                    local: self.local)
            // use this instead of `graph.id` to prevent string duplication
            var element:BasisElement = .init(module, id: trees[global: module].id)
            try element.link(dependencies: culture.dependencies,
                linkable: linkable, 
                fasces: self.local,
                branch: branch,
                trees: trees)
            self.storage.append(element)
        }
    }
}
extension PackageUpdateContext
{
    enum Dependency:Sendable 
    {
        case available(Version)
        case unavailable(Tag, String)
    }

    func pins() -> [Package: Version]
    {
        self.reduce(into: [:]) 
        { 
            for (nationality, pinned):(Package, Tree.Pinned) in $1.upstream
            {
                $0[nationality] = pinned.version
            }
        }
    }
}
extension PackageUpdateContext:RandomAccessCollection
{
    var startIndex:Int
    {
        self.storage.startIndex
    }
    var endIndex:Int
    {
        self.storage.endIndex
    }
    subscript(index:Int) -> ModuleUpdateContext
    {
        let element:BasisElement = self.storage[index]
        return .init(namespaces: element.namespaces,
            upstream: element.upstream, 
            local: self.local)
    }
}

extension PackageUpdateContext
{
    private 
    struct BasisElement 
    {
        private(set)
        var namespaces:Namespaces, 
            upstream:[Package: Tree.Pinned]

        init(_ module:AtomicPosition<Module>, id:ModuleIdentifier)
        {
            self.namespaces = .init(module, id: id)
            self.upstream = [:]
        }
    
        var culture:Module 
        {
            self.namespaces.culture
        }
        var nationality:Package
        {
            self.namespaces.nationality
        }
        // the `branch` parameter may be *different* from `module.position.branch`, 
        // which refers to the branch in which the module itself was founded.
        mutating 
        func link(dependencies:[PackageDependency], 
            linkable:[Package: Dependency], 
            fasces:Fasces,
            branch:Version.Branch,
            trees:Trees) throws
        {
            self.upstream.reserveCapacity(dependencies.count + 2)
            // add explicit dependencies 
            for dependency:PackageDependency in dependencies
            {
                guard let tree:Tree = trees[dependency.nationality]
                else 
                {
                    throw DependencyNotFoundError.package(dependency.nationality)
                }
                if self.nationality == tree.nationality 
                {
                    try self.link(local: tree, dependencies: dependency.cultures, 
                        branch: branch, 
                        fasces: fasces)
                }
                else 
                {
                    try self.link(upstream: tree, dependencies: dependency.cultures, 
                        linkable: linkable)
                }
            }
            // add implicit dependencies
            if self.nationality != .swift 
            {
                try self.link(upstream: .swift, linkable: linkable, trees: trees)
                
                if self.nationality != .core 
                {
                    try self.link(upstream: .core, linkable: linkable, trees: trees)
                }
            }
        }
        private mutating 
        func link(upstream package:PackageIdentifier, 
            linkable:[Package: Dependency], 
            trees:Trees) throws
        {
            if let tree:Tree = trees[package]
            {
                try self.link(upstream: _move tree, linkable: linkable)
            }
            else 
            {
                throw DependencyNotFoundError.package(package)
            }
        }
        private mutating 
        func link(upstream tree:__owned Tree, dependencies:[ModuleIdentifier]? = nil, 
            linkable:[Package: Dependency]) throws 
        {
            switch linkable[tree.nationality] 
            {
            case nil:
                throw DependencyNotFoundError.pin(tree.id)
            case .unavailable(let requirement, let revision):
                throw DependencyNotFoundError.version((requirement, revision), tree.id)
            case .available(let version):
                // upstream dependency 
                let pinned:Tree.Pinned = .init(_move tree, version: version)
                if let dependencies:[ModuleIdentifier] 
                {
                    for id:ModuleIdentifier in dependencies
                    {
                        if let module:AtomicPosition<Module> = pinned.modules.find(id)
                        {
                            // use the stored id, not the requested id
                            let id:ModuleIdentifier = pinned.tree[local: module].id
                            self.namespaces.linked[id] = module
                        }
                        else 
                        {
                            let branch:Branch = pinned.tree[version.branch]
                            throw DependencyNotFoundError.module(id, 
                                (branch.id, branch.revisions[version.revision].commit.hash), 
                                pinned.tree.id)
                        }
                    }
                }
                else 
                {
                    for period:Period<IntrinsicSlice<Module>> in pinned.modules 
                    {
                        for module:Module.Intrinsic in period.axis
                        {
                            self.namespaces.linked[module.id] = module.culture
                                .positioned(period.branch)
                        }
                    }
                }
                self.upstream[pinned.nationality] = pinned
            }
        }
        private mutating 
        func link(local tree:Tree, dependencies:[ModuleIdentifier], 
            branch:Version.Branch, 
            fasces:Fasces) throws 
        {
            let contemporary:IntrinsicSlice<Module> = tree[branch].modules[...]
            for module:ModuleIdentifier in dependencies
            {
                if  let module:AtomicPosition<Module> = 
                        contemporary.atoms[module].map({ $0.positioned(branch) }) ?? 
                        fasces.modules.find(module) 
                {
                    // use the stored id, not the requested id
                    self.namespaces.linked[tree[local: module].id] = module
                }
                else 
                {
                    throw DependencyNotFoundError.target(module, tree[branch].id)
                }
            }
        }
    }
}
