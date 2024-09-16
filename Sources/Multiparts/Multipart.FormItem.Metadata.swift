extension Multipart.FormItem
{
    public
    enum MetadataError:Error
    {
        case missingDisposition
        case invalidDispositionType(String)
    }

    @frozen public
    struct Metadata
    {
        public private(set)
        var filename:String?
        public private(set)
        var name:String?

        public
        let content:MediaType?

        public
        init(disposition:DispositionType?, content:MediaType?) throws
        {
            self.filename = nil
            self.name = nil

            self.content = content

            guard let disposition:DispositionType
            else
            {
                throw MetadataError.missingDisposition
            }
            guard case "form-data" = disposition.type
            else
            {
                throw MetadataError.invalidDispositionType(disposition.type)
            }

            for (name, value):(String, String) in disposition.parameters
            {
                switch name
                {
                case "filename":
                    self.filename = value
                case "name":
                    self.name = value
                default:
                    continue
                }
            }
        }
    }
}

extension Multipart.FormItem.Metadata:CustomStringConvertible
{
    public 
    var description:String
    {
        let disposition:String =
        """
        Content-Disposition: form-data\
        \(self.name.map { "; name=\(Multipart.escape($0))" } ?? "")\
        \(self.filename.map { "; filename=\(Multipart.escape($0))" } ?? "")\r\n
        """
        if let content:MediaType = self.content
        {
            
            return disposition + "Content-Type: \(content.description)\r\n\r\n"
        }
        else
        {
            return disposition + "\r\n"
        }
    }
}
