import HTML
import Notebook
import SymbolSource

extension Organizer 
{
    enum SortingKey:Comparable 
    {
        case atomic   (Path)
        case compound((Path, String))

        static 
        func == (lhs:Self, rhs:Self) -> Bool 
        {
            switch (lhs, rhs)
            {
            case    (.atomic(let a), .atomic(let b)): 
                return a == b 
            
            case    (.atomic(let a), .compound(let b)), 
                    (.compound(let b), .atomic(let a)): 
                return a.last == b.1 && a.prefix.elementsEqual(b.0)
            
            case    (.compound(let a), .compound(let b)): 
                return a == b
            }
        }
        static 
        func < (lhs:Self, rhs:Self) -> Bool 
        {
            switch (lhs, rhs)
            {
            case    (.atomic(let lhs), .atomic(let rhs)): 
                return lhs |<| rhs 
            
            case    (.atomic(let lhs), .compound(let rhs)): 
                return (lhs.prefix, lhs.last) |<| rhs
            
            case    (.compound(let lhs), .atomic(let rhs)): 
                return lhs |<| (rhs.prefix, rhs.last)
            
            case    (.compound(let lhs), .compound(let rhs)): 
                return lhs |<| rhs
            }
        }
    }
}
extension Sequence 
{
    func sorted<T>() -> [T] where Element == (T, Organizer.SortingKey)
    {
        self.sorted { $0.1 < $1.1 } .map(\.0)
    }
}
