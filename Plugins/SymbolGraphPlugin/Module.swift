import PackagePlugin

public 
struct Module<TargetType>
{
    let target:TargetType
    let nationality:Package.ID

    init(_ target:TargetType, in nationality:Package.ID) 
    {
        self.target = target 
        self.nationality = nationality
    }
}

extension Module:Identifiable, Equatable, Comparable where TargetType:Target 
{
    public static 
    func == (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.target.id == rhs.target.id
    }
    public static 
    func < (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.target.id < rhs.target.id
    }
    
    public 
    var id:Target.ID 
    {
        self.target.id
    }
}