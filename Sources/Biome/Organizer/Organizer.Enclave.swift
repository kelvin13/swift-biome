import HTML 
import Notebook

protocol HeadingLevel 
{
    static 
    func html(_:some Sequence<HTML.Element<Never>>) -> HTML.Element<Never>
}

extension Organizer 
{
    enum H3:HeadingLevel 
    {
        static 
        func html(_ elements:some Sequence<HTML.Element<Never>>) -> HTML.Element<Never> 
        { 
            .h3(elements) 
        }
    }
    enum H4:HeadingLevel 
    {
        static 
        func html(_ elements:some Sequence<HTML.Element<Never>>) -> HTML.Element<Never> 
        { 
            .h4(elements) 
        }
    }
    struct Enclave<Heading, ID, Element> where Heading:HeadingLevel
    {
        let id:ID 
        var elements:[Element]

        init(_ id:ID, elements:[Element] = [])
        {
            self.id = id
            self.elements = elements
        }
    }
}
extension Organizer.Enclave 
{
    func sorted<T>() -> Organizer.Enclave<Heading, ID, T> 
        where Element == (T, Organizer.SortingKey)
    {
        .init(self.id, elements: self.elements.sorted())
    }
    func sorted(by order:(Element, Element) throws -> Bool) rethrows -> Self 
    {
        .init(self.id, elements: try self.elements.sorted(by: order))
    }
}
extension Sequence 
{
    func sorted<Heading, ID, T>() -> [Element] 
        where Element == Organizer.Enclave<Heading, ID, T>, ID:Comparable
    {
        self.sorted { $0.id < $1.id } 
    }
}

extension Organizer.Enclave:HTMLConvertible where Element:HTMLConvertible, ID:HTMLConvertible
{
    var htmls:[HTML.Element<Never>] 
    {
        let heading:ID.RenderedHTML = self.id.htmls
        return heading.isEmpty ?   [.ul(self.elements.flatMap(\.htmls))] :
            [Heading.html(heading), .ul(self.elements.flatMap(\.htmls))]
    }
}