struct PluralPosition<Element>:Hashable where Element:BranchElement
{
    let contemporary:Atom<Element>
    let branch:Version.Branch 

    @available(*, deprecated, renamed: "contemporary")
    var index:Element.Index 
    {
        self.contemporary
    }

    init(_ contemporary:Atom<Element>, branch:Version.Branch)
    {
        self.contemporary = contemporary 
        self.branch = branch
    }
}
extension PluralPosition:Sendable where Element.Offset:Sendable, Element.Culture:Sendable
{
}

extension PluralPosition where Element.Culture == Atom<Module>
{
    var nationality:Package.Index 
    {
        self.contemporary.nationality
    }
    @available(*, deprecated, renamed: "nationality")
    var package:Package.Index 
    {
        self.nationality
    }
    
    @available(*, unavailable, 
        message: "a module does not necessarily reside in the same branch segment as its symbols")
    var module:PluralPosition<Module>
    {
        fatalError()
    }
}
extension PluralPosition<Module> 
{
    var nationality:Package.Index 
    {
        self.contemporary.nationality
    }
    @available(*, deprecated, renamed: "nationality")
    var package:Package.Index 
    {
        self.nationality
    }
}