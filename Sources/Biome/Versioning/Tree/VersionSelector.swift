import Versions 

enum VersionSelector 
{
    case tag(Tag)
    case date(Tag?, Date)
}
extension VersionSelector 
{
    init?(parsing string:some StringProtocol)
    {
        if  let colon:String.Index = string.lastIndex(of: ":"),
            let date:Date = try? .init(parsing: string.suffix(from: string.index(after: colon)))
        {
            if let tag:Tag = .init(parsing: string.prefix(upTo: colon))
            {
                self = .date(tag, date) 
            }
            else 
            {
                self = .date(nil, date)
            }
        }
        else if let date:Date = try? .init(parsing: string)
        {
            self = .date(nil, date)
        }
        else if let tag:Tag = .init(parsing: string)
        {
            self = .tag(tag)
        }
        else 
        {
            return nil
        }
    }
}
extension VersionSelector:CustomStringConvertible 
{
    var description:String
    {
        switch self 
        {
        case .tag(let tag): 
            return tag.description 
        case .date(nil, let date): 
            return date.description 
        case .date(let tag?, let date): 
            return "\(tag):\(date)"
        }
    }
}