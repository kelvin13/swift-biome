import SymbolSource

//  the endpoints of a graph edge can reference symbols in either this 
//  package or one of its dependencies. since imports are module-wise, and 
//  not package-wise, it’s possible for multiple index dictionaries to 
//  return matches, as long as only one of them belongs to an depended-upon module.
//  
//  it’s also possible to prefer a dictionary result in a foreign package over 
//  a dictionary result in the local package, if the foreign package contains 
//  a module that shadows one of the modules in the local package (as long 
//  as the target itself does not also depend upon the shadowed local module.)
struct ModuleUpdateContext
{
    let namespaces:Namespaces
    let upstream:[Packages.Index: Package.Pinned]
    let local:Fasces

    var nationality:Packages.Index
    {
        self.namespaces.nationality
    }
    var culture:Atom<Module> 
    {
        self.namespaces.culture
    }
    var id:ModuleIdentifier
    {
        self.namespaces.id
    }
    var module:Atom<Module>.Position
    {
        self.namespaces.module
    }
    var linked:[ModuleIdentifier: Atom<Module>.Position]
    {
        self.namespaces.linked
    }
}