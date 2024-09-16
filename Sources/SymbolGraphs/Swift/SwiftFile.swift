@frozen public
struct SwiftFile:Equatable, Sendable
{
    public
    let uri:String
    public
    let features:[Feature]
}