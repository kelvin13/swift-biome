import JSON

extension SwiftFile
{
    private
    enum CodingKeys
    {
        static let uri:String = "uri"
        static let features:String = "features"
    }

    var serialized:JSON
    {
        [
            CodingKeys.uri: .string(self.uri),
            CodingKeys.features: .array(self.features.flatMap 
            { 
                [
                    .number($0.line),
                    .number($0.character),
                    .number($0.vertex),
                ]
            })
        ]
    }

    init(from json:JSON) throws
    {
        self = try json.lint 
        {
            .init(
                uri: try $0.remove(CodingKeys.uri, as: String.self),
                features: try $0.remove(CodingKeys.features)
                {
                    let flattened:[JSON] = try $0.as([JSON].self) { $0 % 3 == 0 }
                    var sourcemap:[Feature] = []
                        sourcemap.reserveCapacity(flattened.count / 3)
                    for start:Int in stride(
                        from: flattened.startIndex, 
                        to: flattened.endIndex, 
                        by: 3)
                    {
                        sourcemap.append(.init(line: try flattened.load(start), 
                            character: try flattened.load(start + 1),
                            vertex: try flattened.load(start + 2)))
                    }
                    return sourcemap
                })
        }
    }
}