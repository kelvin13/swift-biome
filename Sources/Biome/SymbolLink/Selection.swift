enum Selection<Element>
{
    case one(Element)
    case many([Element])
            
    init?(_ elements:[Element]) 
    {
        if let first:Element = elements.first 
        {
            self = elements.count < 2 ? .one(first) : .many(elements)
        }
        else 
        {
            return nil
        }
    }

    @available(*, unavailable, 
        message: "append(_:) is only available on Optional<Self>, to prevent accidental dropping of values.")
    mutating 
    func append(_:Element) 
    {
    }
}
extension Optional 
{
    // func unique<Element>() throws -> Element where Wrapped == Selection<Element>
    // {
    //     switch self 
    //     {
    //     case nil: 
    //         throw SelectionError<Element>.none
    //     case .one(let element)?:
    //         return element
    //     case .many(let elements)?: 
    //         throw SelectionError<Element>.many(elements)
    //     }
    // }

    mutating 
    func append<Element>(_ element:Element) where Wrapped == Selection<Element>
    {
        switch _move self 
        {
        case nil: 
            self = .one(element)
        case .one(let first)?: 
            self = .many([first, element])
        case .many(var elements)?: 
            elements.append(element)
            self = .many(elements)
        }
    }
}
