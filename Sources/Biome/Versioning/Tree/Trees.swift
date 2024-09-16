import PackageResolution
import SymbolGraphs
import SymbolSource
import Versions

struct Trees
{
    private 
    var trees:[Tree]
    private(set)
    var packages:[PackageIdentifier: Package]
    
    init()
    {
        self.trees = []
        self.packages = [:]

        // swift-standard-library is always index = 0
        // swift-core-libraries is always index = 1
        let swift:Package = self.addPackage(.swift)
        let core:Package = self.addPackage(.core)

        precondition(swift == .swift) 
        precondition(core == .core) 
    }
}
extension Trees
{
    /// Creates a package entry for the given package graph, if it does not already exist.
    /// 
    /// -   Returns: The index of the package, identified by its ``PackageIdentifier``.
    mutating 
    func addPackage(_ package:PackageIdentifier) -> Package
    {
        if let packages:Package = self.packages[package]
        {
            return packages 
        }
        else 
        {
            let packages:Package = self.endIndex
            self.trees.append(.init(id: package, nationality: packages))
            self.packages[package] = packages
            return packages
        }
    }
}
extension Trees:RandomAccessCollection
{
    var startIndex:Package
    {
        .init(offset: .init(self.trees.startIndex))
    }
    var endIndex:Package
    {
        .init(offset: .init(self.trees.endIndex))
    }
    subscript(package:Package) -> Tree
    {
        _read 
        {
            yield  self.trees[.init(package.offset)]
        }
        _modify 
        {
            yield &self.trees[.init(package.offset)]
        }
    } 
}
extension Trees 
{
    var swift:Tree 
    {
        _read 
        {
            yield self[.swift]
        }
    }
    var core:Tree 
    {
        _read 
        {
            yield self[.core]
        }
    }
    
    subscript(package:PackageIdentifier) -> Tree?
    {
        self.packages[package].map { self[$0] }
    }
    

    subscript(global module:AtomicPosition<Module>) -> Module.Intrinsic
    {
        _read 
        {
            yield self[module.nationality][local: module]
        }
    } 
    subscript(global article:AtomicPosition<Article>) -> Article.Intrinsic
    {
        _read 
        {
            yield self[article.nationality][local: article]
        }
    } 
    subscript(global symbol:AtomicPosition<Symbol>) -> Symbol.Intrinsic
    {
        _read 
        {
            yield self[symbol.nationality][local: symbol]
        }
    } 
}
extension Trees
{
    func find(pins:some Sequence<PackageResolution.Pin>) 
        -> [Index: PackageUpdateContext.Dependency]
    {
        var linkable:[Index: PackageUpdateContext.Dependency] = [:]
        for pin:PackageResolution.Pin in pins 
        {
            guard   let tree:Tree = self[pin.id],
                    let tag:Tag = .init(pin.requirement)
            else 
            {
                continue 
            }
            if  let version:Version = tree.find(tag),
                    tree[version].commit.hash == pin.revision
            {
                linkable[tree.nationality] = .available(version)
            }
            else 
            {
                linkable[tree.nationality] = .unavailable(tag, pin.revision)
            }
        }
        return linkable
    }
}
extension Trees 
{
    /// Returns the index of the package referenced by the given identifier, and 
    /// the fork location within it, if a fork selector is provided.
    /// 
    /// This method will only create package descriptors if `fork` is [`nil`]().
    // private mutating 
    // func add(package id:PackageIdentifier, fork:VersionSelector?) -> (Index, Version?)
    // {
    //     if  let fork:VersionSelector 
    //     {
    //         guard   let package:Index = self.index[id], 
    //                 let fork:Version = self[package].tree.find(fork)
    //         else 
    //         {
    //             fatalError("couldn’t find tag to fork from")
    //         }
    //         // guard case fork.revision? = self[package].tree[fork.branch].head 
    //         // else 
    //         // {
    //         //     // we can relax this restriction once we have a way of persisting 
    //         //     // API surfaces for revisions besides the branch head 
    //         //     fatalError("can only fork from branch head (for now)")
    //         // }
    //         return (package, fork)
    //     }
    //     else 
    //     {
    //         return (self.add(package: id), nil)
    //     }
    // }
    

    // private mutating
    // func commit(_ revision:String, 
    //     to branch:Version.Branch, 
    //     of nationality:Index, 
    //     interfaces:[ModuleInterface], 
    //     date:Date, 
    //     tag:Tag?) -> Version
    // {
    //     var pins:[Index: (version:Version, consumers:Set<Module>)] = [:]
    //     for interface:ModuleInterface in interfaces 
    //     {
    //         for (package, pin):(Index, Version) in interface.pins 
    //         {
    //             pins[package, default: (pin, [])].consumers.insert(interface.culture)
    //         }
    //     }
    //     let version:Version = self[nationality].tree.commit(branch: branch, hash: revision, 
    //         pins: pins.mapValues(\.version), 
    //         date: date, 
    //         tag: tag)
    //     for (package, (pin, consumers)):(Index, (Version, Set<Module>)) in pins
    //     {
    //         assert(package != nationality)
    //         self[package].tree[pin].consumers[nationality, default: [:]][version] = consumers
    //     }
    //     return version
    // }
}
