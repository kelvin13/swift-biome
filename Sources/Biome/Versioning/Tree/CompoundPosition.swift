struct CompoundPosition 
{
    let atoms:Compound 
    private 
    let branches:
    (
        base:Version.Branch, 
        host:Version.Branch, 
        culture:Version.Branch
    )

    init(_ atoms:Compound,
        culture:Version.Branch, 
        host:Version.Branch, 
        base:Version.Branch)
    {
        self.branches.culture = culture
        self.branches.host = host
        self.branches.base = base
        self.atoms = atoms 
    }
}
extension CompoundPosition
{
    var nationality:Package
    {
        self.atoms.culture.nationality
    }
    var culture:AtomicPosition<Module>
    {
        .init(self.atoms.culture, branch: self.branches.culture)
    }
    var host:AtomicPosition<Symbol>
    {
        .init(self.atoms.host, branch: self.branches.host)
    }
    var base:AtomicPosition<Symbol>
    {
        .init(self.atoms.base, branch: self.branches.base)
    }
}

extension Compound 
{
    func positioned(
        bisecting trunk:some RandomAccessCollection<Period<IntrinsicSlice<Module>>>, 
        host:some RandomAccessCollection<Period<IntrinsicSlice<Symbol>>>, 
        base:some RandomAccessCollection<Period<IntrinsicSlice<Symbol>>>) -> CompoundPosition?
    {
        if  let culture:Version.Branch = self.culture.positioned(bisecting: trunk)?.branch, 
            let host:Version.Branch = self.host.positioned(bisecting: host)?.branch,
            let base:Version.Branch = self.base.positioned(bisecting: base)?.branch
        {
            return .init(self, culture: culture, host: host, base: base)
        }
        else 
        {
            return nil
        }
    }
}