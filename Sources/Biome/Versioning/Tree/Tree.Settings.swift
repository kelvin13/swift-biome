import SymbolSource 

extension Tree 
{
    struct Settings 
    {
        var brand:String?
        var whitelist:Set<PackageIdentifier>?

        init(whitelist:Set<PackageIdentifier>? = nil, brand:String? = nil)
        {
            self.whitelist = whitelist 
            self.brand = brand
        }
    }
}