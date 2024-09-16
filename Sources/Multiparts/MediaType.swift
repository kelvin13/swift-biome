@frozen public
struct MediaType
{
    public
    let type:String
    public
    let subtype:String
    public
    let parameters:[(name:String, value:String)]

    public
    init(type:String, subtype:String,
        parameters:[(name:String, value:String)])
    {
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }
}
extension MediaType:CustomStringConvertible
{
    public 
    var description:String
    {
        """
        \(self.type)/\(self.subtype)\
        \(self.parameters.lazy.map 
        { 
            "; \($0.name)=\(Multipart.escape($0.value))" 
        }.joined() as String)
        """
    }
}