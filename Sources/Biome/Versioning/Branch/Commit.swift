import Versions 

struct Commit:Sendable
{
    let hash:String
    let date:Date
    let tag:Tag?
}