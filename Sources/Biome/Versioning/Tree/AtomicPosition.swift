struct AtomicPosition<Atom> where Atom:AtomicReference
{
    let atom:Atom
    let branch:Version.Branch 

    init(_ atom:Atom, branch:Version.Branch)
    {
        self.atom = atom
        self.branch = branch
    }

    var nationality:Package
    {
        self.atom.nationality
    }
    var culture:Module 
    {
        self.atom.culture
    }
}
extension AtomicPosition:Sendable where Atom:Sendable {}
extension AtomicPosition:Equatable where Atom:Equatable {}
extension AtomicPosition:Hashable where Atom:Hashable {}

extension AtomicReference
{
    func positioned(_ branch:Version.Branch) -> AtomicPosition<Self>
    {
        .init(self, branch: branch)
    }
}
