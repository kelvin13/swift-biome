extension Mongo
{
    @frozen public
    struct MessageTypeError:Equatable, Error
    {
        public
        let code:Int32

        @inlinable public
        init(invalid code:Int32)
        {
            self.code = code
        }
    }
}
extension Mongo.MessageTypeError:CustomStringConvertible
{
    public
    var description:String
    {
        "invalid or unsupported message operation code (\(self.code))"
    }
}
