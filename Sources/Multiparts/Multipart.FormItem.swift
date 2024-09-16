import Grammar

extension Multipart
{
    @frozen public
    struct FormItem
    {
        public
        let metadata:Metadata
        public
        let value:ArraySlice<UInt8>

        @inlinable public
        var filename:String?
        {
            self.metadata.filename
        }
        @inlinable public
        var name:String?
        {
            self.metadata.name
        }
        @inlinable public
        var content:MediaType?
        {
            self.metadata.content
        }
    }

    public
    func form() throws -> [FormItem]
    {
        try self.map
        {
            var input:ParsingInput<NoDiagnostics<ArraySlice<UInt8>>> = .init($0)
            let metadata:FormItem.Metadata = try input.parse(as: Rule<Int>.SubHeaders.self)
            return .init(metadata: metadata, value: $0.suffix(from: input.index))
        }
    }
}
extension Multipart.FormItem:CustomStringConvertible
{
    public 
    var description:String
    {
        """
        \(self.metadata.description)\(String.init(decoding: self.value, as: Unicode.UTF8.self))
        """
    }
}