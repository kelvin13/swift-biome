extension DecodingError
{
    init<T>(annotating error:any Error, initializing _:T.Type, path:[any CodingKey]) 
    {
        let description:String =
        """
        initializer for type '\(String.init(reflecting: T.self))' \
        threw an error while validating json value at coding path \(path)
        """
        let context:DecodingError.Context = .init(codingPath: path, 
            debugDescription: description, underlyingError: error)
        self = .dataCorrupted(context)
    }
}

extension BSON
{
    struct TupleKey:CodingKey 
    {
        let value:Int
        var intValue:Int? 
        {
            self.value 
        }
        var stringValue:String
        {
            "\(self.value)"
        }
        
        init(intValue:Int)
        {
            self.value = intValue
        }
        init?(stringValue:String)
        {
            guard let value:Int = Int.init(stringValue)
            else 
            {
                return nil 
            }
            self.value = value
        }
    }
    enum ObjectKey:String, CodingKey 
    {
        case `super` = "super"
    }
}

extension BSON 
{
    /// A single-value decoding container, for use with compiler-generated ``Decodable`` 
    /// implementations.
    public 
    struct Decoder<Bytes> where Bytes:RandomAccessCollection<UInt8>
    {
        let value:Variant<Bytes>
        public 
        let codingPath:[any CodingKey]
        public 
        let userInfo:[CodingUserInfoKey: Any]
        
        public 
        init(_ value:Variant<Bytes>, path:[any CodingKey],
            userInfo:[CodingUserInfoKey: Any] = [:])
        {
            self.value = value 
            self.codingPath = path 
            self.userInfo = userInfo
        }
    }
}
extension BSON.Decoder
{
    func diagnose<T>(_ decode:(T.Type) throws -> T) throws -> T
    {
        do 
        {
            return try decode(T.self)
        }
        catch let error
        {
            throw DecodingError.init(annotating: error, initializing: T.self,
                path: self.codingPath)
        }
    }
}
extension BSON.Decoder:Decoder
{
    public 
    func singleValueContainer() -> any SingleValueDecodingContainer
    {
        self as any SingleValueDecodingContainer
    }
    public 
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer
    {
        BSON.UnkeyedDecoder<Bytes.SubSequence>.init(try self.diagnose(self.value.as(_:)),
            path: self.codingPath) as any UnkeyedDecodingContainer
    }
    public 
    func container<Key>(keyedBy _:Key.Type) throws -> KeyedDecodingContainer<Key> 
        where Key:CodingKey 
    {
        let container:BSON.KeyedDecoder<Bytes.SubSequence, Key> = 
            .init(try self.diagnose(self.value.as(_:)), path: self.codingPath)
        return .init(container)
    }
}

extension BSON.Variant:Decoder 
{
    @inlinable public 
    var codingPath:[any CodingKey] 
    {
        []
    }
    @inlinable public 
    var userInfo:[CodingUserInfoKey: Any] 
    {
        [:]
    }

    @inlinable public 
    func singleValueContainer() -> SingleValueDecodingContainer
    {
        BSON.Decoder<Bytes>.init(self, path: []) as SingleValueDecodingContainer
    }
    @inlinable public 
    func unkeyedContainer() throws -> UnkeyedDecodingContainer
    {
        try BSON.Decoder<Bytes>.init(self, path: []).unkeyedContainer()
    }
    @inlinable public 
    func container<Key>(keyedBy _:Key.Type) throws -> KeyedDecodingContainer<Key> 
        where Key:CodingKey 
    {
        try BSON.Decoder<Bytes>.init(self, path: []).container(keyedBy: Key.self)
    }
}
