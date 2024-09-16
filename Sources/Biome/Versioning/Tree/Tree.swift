import SymbolGraphs
import SymbolSource
import Versions

struct VersionNotFoundError:Error 
{
    let selector:VersionSelector

    init(_ selector:VersionSelector)
    {
        self.selector = selector
    }
}

struct Tree:Sendable
{
    let id:PackageIdentifier
    let nationality:Package
    private 
    var storage:[Branch]
    private(set)
    var branches:[Branch.ID: Version.Branch]
    private
    var tags:[Tag: Version]
    private 
    var counter:UInt
    var settings:Settings 

    init(id:PackageIdentifier, nationality:Package)
    {
        self.id = id 

        self.nationality = nationality 
        self.storage = []
        self.branches = [:]
        self.tags = [:]
        self.counter = 0

        switch id 
        {
        case .swift, .core: 
            self.settings = .init(brand: "Swift")
        case .community(_):
            self.settings = .init()
        }
    }

    var `default`:Version? 
    {
        nil
    }
}
extension Tree
{
    var name:String 
    {
        self.id.string
    }

    func latest() -> Pinned?
    {
        self.default.map { .init(self, version: $0) }
    }
}
extension Tree:RandomAccessCollection
{
    var startIndex:Version.Branch 
    {
        .init(.init(self.storage.startIndex))
    }
    var endIndex:Version.Branch 
    {
        .init(.init(self.storage.endIndex))
    }
    var indices:Range<Version.Branch> 
    {
        self.startIndex ..< self.endIndex
    }
    subscript(branch:Version.Branch) -> Branch 
    {
        _read 
        {
            yield  self.storage[.init(branch.offset)]
        }
        _modify
        {
            yield &self.storage[.init(branch.offset)]
        }
    }
}
extension Tree 
{
    subscript(version:Version) -> Branch.Revision
    {
        _read 
        {
            yield  self[version.branch].revisions[version.revision]
        }
        _modify
        {
            yield &self[version.branch].revisions[version.revision]
        }
    }
}
extension Tree 
{
    func root(of branch:Version.Branch) -> Branch 
    {
        var root:Branch = self[branch]
        while let fork:Version.Branch = root.fork?.branch 
        {
            root = self[fork]
        }
        return root
    }
    
    func fasces(upTo branch:Version.Branch) -> Fasces
    {
        var current:Branch = self[branch]
        var fasces:[Fascis] = []
        while let fork:Version = current.fork 
        {
            current = self[fork.branch]
            fasces.append(current[...fork.revision])
        }
        return .init(fasces)
    }
    func fasces(through version:Version) -> Fasces
    {
        var current:Branch = self[version.branch]
        var fasces:[Fascis] = [current[...version.revision]]
        while let fork:Version = current.fork 
        {
            current = self[fork.branch]
            fasces.append(current[...fork.revision])
        }
        return .init(fasces)
    }
}
extension Tree 
{
    /// Returns the version pointed to by the given version selector, if it exists. 
    /// 
    /// If the selector specifies a date, the tag component (if present) is 
    /// assumed to point to a branch. If no tag component is specified, 
    /// the default branch is used.
    func find(_ selector:VersionSelector) -> Version? 
    {
        switch selector 
        {
        case .tag(let tag):
            return self.find(tag)
        case .date(nil, let date):
            if  let branch:Version.Branch = self.default?.branch, 
                let revision:Version.Revision = self[branch].revisions.find(date)
            {
                return .init(branch, revision)
            }
            else 
            {
                return nil 
            }
        
        case .date(let tag?, let date):
            if  let branch:Version.Branch = self.branches[tag], 
                let revision:Version.Revision = self[branch].revisions.find(date)
            {
                return .init(branch, revision)
            }
            else 
            {
                return nil 
            }
        }
    }
    /// Returns the version pointed to by the given tag, if it exists. 
    /// 
    /// If the given tag refers to a branch, this method returns the 
    /// head of that branch.
    func find(_ tag:Tag) -> Version?
    {
        self.tags[tag] ?? self.branches[tag].flatMap { self[$0].latest }
    }
    /// Returns the preferred name for referring to the specified version.
    /// 
    /// -   Returns: 
    ///     -   [`nil`](), if `version` is the head of the default branch; otherwise
    /// 
    ///     -   The branch name, if `version` is the head of its branch; otherwise
    /// 
    ///     -   The custom tag name associated with the revision pointed to by 
    ///         `version`, if one exists; otherwise 
    ///
    ///     -   The date of the revision pointed to by `version`, if its branch 
    ///         is the default branch; otherwise 
    /// 
    ///     -   The branch name and date of the revision pointed to by `version`.
    func abbreviate(_ version:Version) -> VersionSelector?
    {
        let branch:Branch = self[version.branch]
        let revision:Branch.Revision = branch.revisions[version.revision]
        if case version? = self.default 
        {
            return nil
        }
        else if case version.revision? = branch.head 
        {
            return .tag(branch.id)
        }
        else if let custom:Tag = revision.tag 
        {
            return .tag(custom)
        }
        else if case version.branch? = self.default?.branch
        {
            return .date(nil, revision.date)
        }
        else 
        {
            return .date(branch.id, revision.date)
        }
    }
}
extension Tree 
{
    mutating 
    func branch(_ name:Branch.ID, from fork:VersionSelector?) 
        throws -> (branch:Version.Branch, previous:Version?)
    {
        if  let branch:Version.Branch = self.branches[name]
        {
            // pushing to an existing branch (ignores `fork` argument)
            return (branch, self[branch].latest) 
        }

        let branch:Version.Branch = self.endIndex

        guard let fork:VersionSelector
        else 
        {
            // creating a new branch
            self.storage.append(.init(id: name, index: branch, fork: nil))
            self.branches[name] = branch 
            return (branch, nil) 
        }
        guard let fork:Version = self.find(fork)
        else 
        {
            throw VersionNotFoundError.init(fork)
        }

        let ring:Branch.Ring = self[fork].branch(branch)
        self.storage.append(.init(id: name, index: branch, fork: (fork, ring)))
        self.branches[name] = branch 
        return (branch, fork) 
    }
    
    mutating 
    func commit(_ commit:__owned Commit, to branch:Version.Branch, 
        pins:__owned [Package: Version]) -> Version
    {
        defer 
        {
            self.counter += 1
        }
        return self[branch].commit(commit, token: self.counter, pins: pins)
    }

    mutating 
    func revert(_ branch:Version.Branch, to previous:Version?)
    {
        self.counter += 1
        if  let previous:Version,
                previous.branch == branch
        {
            self[branch].revert(to: previous.revision)
        }
        else //if case _? = self[previous].alternates.remove(branch)
        {
            self[branch].revert()
        }
    }
}

extension Tree 
{
    subscript(local article:AtomicPosition<Article>) -> Article.Intrinsic
    {
        _read 
        {
            yield  self[article.branch].articles[contemporary: article.atom]
        }
        _modify
        {
            yield &self[article.branch].articles[contemporary: article.atom]
        }
    }
    subscript(local symbol:AtomicPosition<Symbol>) -> Symbol.Intrinsic
    {
        _read 
        {
            yield  self[symbol.branch].symbols[contemporary: symbol.atom]
        }
        _modify
        {
            yield &self[symbol.branch].symbols[contemporary: symbol.atom]
        }
    }
    subscript(local module:AtomicPosition<Module>) -> Module.Intrinsic
    {
        _read 
        {
            yield  self[module.branch].modules[contemporary: module.atom]
        }
        _modify 
        {
            yield &self[module.branch].modules[contemporary: module.atom]
        }
    }

    subscript(article:AtomicPosition<Article>) -> Article.Intrinsic? 
    {
        self.nationality == article.nationality ? self[local: article] : nil
    }
    subscript(symbol:AtomicPosition<Symbol>) -> Symbol.Intrinsic? 
    {
        self.nationality == symbol.nationality ? self[local: symbol] : nil
    }
    subscript(module:AtomicPosition<Module>) -> Module.Intrinsic? 
    {
        self.nationality == module.nationality ? self[local: module] : nil
    }
}

extension Tree
{
    mutating 
    func updateMetadata(interface:PackageInterface, 
        branch:Version.Branch, 
        graph:SymbolGraph,
        stems:Route.Stems, 
        api:inout SurfaceBuilder)
    {
        for (culture, interface):(SymbolGraph.Culture, ModuleInterface) in 
            zip(graph.cultures, interface)
        {
            api.update(with: culture.edges, interface: interface, local: self)
        }

        self[branch].routes.stack(routes: api.routes.atomic, 
            revision: interface.revision)
        self[branch].routes.stack(routes: api.routes.compound.joined(),
            revision: interface.revision)

        api.inferScopes(for: &self[branch], fasces: interface.local, stems: stems)

        self[interface.branch].updateMetadata(interface: interface, builder: api)
    }

    mutating 
    func updateData(_ graph:__owned SymbolGraph, 
        interface:PackageInterface)
    {
        let version:Version = interface.version
        for (culture, interface):(SymbolGraph.Culture, ModuleInterface) in 
            zip((_move graph).cultures, interface)
        {
            self[version.branch].updateDeclarations(culture, 
                interface: interface, 
                revision: version.revision)

            var topLevelSymbols:Set<Symbol> = [] 
            for position:AtomicPosition<Symbol>? in interface.citizens
            {
                if  let position:AtomicPosition<Symbol>, 
                    self[local: position].path.prefix.isEmpty
                {
                    // a symbol is toplevel if it has a single path component. this 
                    // is not the same thing as having a `nil` shape.
                    topLevelSymbols.insert(position.atom)
                }
            }
            self[version.branch].updateTopLevelSymbols(topLevelSymbols, 
                interface: interface,
                revision: version.revision)
            

            let topLevelArticles:Set<Article> = 
                .init(interface.articles.lazy.compactMap { $0?.atom })
            self[version.branch].updateTopLevelArticles(topLevelArticles, 
                interface: interface,
                revision: version.revision)
        }
    }
    mutating 
    func updateDocumentation(_ documentation:__owned PackageDocumentation,
        interface:PackageInterface)
    {
        self[interface.branch].updateDocumentation(_move documentation, 
            interface: interface)
    }
}