import HTML 

struct Navigator
{
    let nationality:PackageReference 
    let searchable:[String]
    let brand:String? 

    init(local:__shared Tree.Pinned, searchable:[String], 
        functions:__shared Service.PublicFunctionNames)
    {
        self.nationality = .init(local, functions: functions)
        self.searchable = searchable
        self.brand = local.tree.settings.brand
    }
}

extension Navigator 
{
    var station:HTML.Element<Never> 
    {
        .span(self.nationality.name.station)
    }
    var constants:String
    {
        """
        searchIndices = [\(self.searchable.map { "'\($0)'" }.joined(separator: ","))];
        """
    }
    var title:String 
    {
        if let brand:String = self.brand 
        {
            return "\(brand) Documentation"
        }
        else 
        {
            return self.nationality.name.string
        }
    }
    func title(_ title:some StringProtocol) -> String
    {
        if  let brand:String = self.brand 
        {
            return "\(title) - \(brand) Documentation"
        }
        else 
        {
            return .init(title)
        }
    }
}