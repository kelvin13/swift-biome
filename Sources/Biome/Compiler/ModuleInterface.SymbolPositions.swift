import SymbolGraphs
import SymbolSource

extension ModuleInterface
{
    struct SymbolLookupError:Error 
    {
        let index:Int 

        init(_ index:Int)
        {
            self.index = index
        }
    }
    struct SymbolPositions
    {
        private
        let positions:[AtomicPosition<Symbol>?]
        private
        let citizens:Range<Int>

        init(_ positions:[AtomicPosition<Symbol>?], citizens:Range<Int>)
        {
            self.positions = positions
            self.citizens = citizens
        }
    }
}
extension ModuleInterface.SymbolPositions
{
    subscript(index:Int) -> AtomicPosition<Symbol>? 
    {
        self.positions[index]
    }

    func citizens(culture:Module) -> ModuleInterface.SymbolCitizens
    {
        .init(positions: self.positions[self.citizens], culture: culture)
    }
}