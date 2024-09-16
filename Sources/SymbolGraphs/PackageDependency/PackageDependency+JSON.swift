import SymbolSource
import JSON

extension PackageDependency 
{
    private
    enum CodingKeys 
    {
        static let nationality:String = "nationality"
        static let cultures:String = "cultures"
    }
    public
    var serialized:JSON 
    {
        [
            CodingKeys.nationality: .string(self.nationality.string),
            CodingKeys.cultures: .array(self.cultures.map { .string($0.string) }),
        ]
    }
    public
    init(from json:JSON) throws 
    {
        self = try json.lint 
        {
            .init(
                nationality: try $0.remove(CodingKeys.nationality, as: String.self, 
                    PackageIdentifier.init(_:)),
                cultures: try $0.remove(CodingKeys.cultures, as: [JSON].self) 
                {
                    try $0.map { ModuleIdentifier.init(try $0.as(String.self)) }
                })
        }
    }
}
