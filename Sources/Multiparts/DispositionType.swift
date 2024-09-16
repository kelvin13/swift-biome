@frozen public
struct DispositionType
{
    let type:String
    let parameters:[(name:String, value:String)]

    public
    init(type:String,
        parameters:[(name:String, value:String)])
    {
        self.type = type
        self.parameters = parameters
    }
}
