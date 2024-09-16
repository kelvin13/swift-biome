import BiomeDatabase
import DOM
import PackageResolution
import SymbolSource
import SymbolGraphs
import Versions

public 
actor Service 
{
    var trees:Trees, 
        stems:Route.Stems

    private
    var functions:Functions
    private
    var template:DOM.Flattened<PageElement>
    private
    let logo:[UInt8]

    let database:Database
    
    public
    init(database:Database, logo:[UInt8])
    {
        self.trees = .init()
        self.stems = .init()

        self.functions = .init([:])
        self.template = .init(freezing: .defaultPageTemplate)

        self.database = database
        self.logo = logo
    }
}
extension Service
{
    var state:State
    {
        .init(trees: self.trees, stems: self.stems, 
            functions: self.functions, 
            template: self.template, 
            logo: self.logo)
    }
}

extension Service
{
    func enable(function namespace:ModuleIdentifier, nationality:Package, 
        template:DOM.Flattened<PageElement>? = nil) -> Bool 
    {
        if  let position:AtomicPosition<Module> = 
                self.trees[nationality].latest()?.modules.find(namespace),
                self.functions.create(namespace, 
                    nationality: nationality, 
                    template: template ?? self.template)
        {
            self.trees[nationality][local: position].isFunction = true
            return true 
        }
        else 
        {
            return false 
        }
    }

    func updatePackage(resolution:PackageResolution,
        branch:String, 
        fork:String? = nil,
        date:Date, 
        tag:String? = nil,
        graph:__owned SymbolGraph) async throws -> Package
    {
        try Task.checkCancellation()

        guard let pin:PackageResolution.Pin = resolution.pins[graph.id]
        else 
        {
            fatalError("missing pin for '\(graph.id)'")
        }
        guard let branch:Tag = .init(parsing: branch) 
        else 
        {
            fatalError("branch name cannot be empty")
        }

        let fork:VersionSelector? = fork.flatMap(VersionSelector.init(parsing:))

        let nationality:Package = self.trees.addPackage(graph.id)

        let impact:PackageImpact = try await self.updatePackage(nationality, 
            resolution: resolution, 
            commit: .init(hash: pin.revision, date: date, tag: tag.flatMap(Tag.init(parsing:))),
            branch: branch, 
            fork: fork,
            graph: _move graph)
        
        for (dependency, (pin, consumers)):(Package, (Version, Set<Module>)) in 
            impact.dependencies
        {
            assert(dependency != nationality)

            self.trees[dependency][pin].consumers[nationality, default: [:]][impact.version] = 
                consumers
        }

        return nationality
    }

    private  
    func updatePackage(_ nationality:Package,
        resolution:__owned PackageResolution, 
        commit:__owned Commit,
        branch:Tag, 
        fork:VersionSelector?,
        graph:__owned SymbolGraph) async throws -> PackageImpact
    {
        let (branch, previous):(Version.Branch, Version?) = 
            try self.trees[nationality].branch(branch, from: fork)

        // we are going to mutate `self[package].tree[branch]`, so we must not 
        // capture that buffer or any slice of it!
        var api:SurfaceBuilder 
        if let previous:Version 
        {
            api = .init(previous: try await self.database.loadSurface(for: nationality, 
                version: previous))
        }
        else 
        {
            api = .init(previous: .init())
        }
        
        do 
        {
            let context:PackageUpdateContext = try .init(resolution: _move resolution,
                nationality: nationality,
                branch: branch,
                graph: graph,
                trees: &self.trees)
            
            let interface:PackageInterface = .init(context: _move context, commit: _move commit, 
                branch: branch,
                graph: graph,
                stems: &self.stems,
                tree: &self.trees[nationality])
            
            self.trees[nationality].updateMetadata(interface: interface,
                branch: branch,
                graph: graph,
                stems: self.stems,
                api: &api)
            
            let documentation:PackageDocumentation = .init(interface: interface, 
                graph: graph,
                local: self.trees[nationality], 
                stems: stems)
            
            let surface:Surface = (_move api).surface()
            try await self.database.storeSurface(_move surface, for: nationality, 
                version: interface.version)
            // try await self.database.storeDocumentation(documentation)

            self.trees[nationality].updateDocumentation(_move documentation, 
                interface: interface)
            self.trees[nationality].updateData(_move graph,
                interface: interface)
            
            return .init(interface: _move interface)
        }
        catch let error
        {
            self.trees[nationality].revert(branch, to: previous)
            throw error
        }
    }
}