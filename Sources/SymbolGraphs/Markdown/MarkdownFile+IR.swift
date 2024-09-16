import JSON

extension MarkdownFile
{
    private
    enum CodingKeys
    {
        static let name:String = "name"
        static let source:String = "source"
    }

    var serialized:JSON
    {
        [ 
            CodingKeys.name: .string(self.name), 
            CodingKeys.source: .string(self.source) 
        ]
    }

    init(from json:JSON) throws
    {
        self = try json.lint
        {
            .init(
                name:   try $0.remove(CodingKeys.name,   as: String.self),
                source: try $0.remove(CodingKeys.source, as: String.self)
            )
        }
    }
}
