@frozen public 
struct Date:Hashable, Sendable 
{
    public 
    enum ComponentError<Integer>:Error where Integer:BinaryInteger
    {
        case month(Integer)
        case day(Integer)
    }
    public 
    enum YearError<Integer>:Error where Integer:BinaryInteger
    {
        case gregorian(Integer)
    }

    @frozen public 
    struct Component:Hashable, Sendable
    {
        public
        let value:UInt8

        @inlinable public
        init(_ value:UInt8)
        {
            self.value = value
        }
    }
    @frozen public 
    struct Year:Hashable, Sendable
    {
        public
        let offset:UInt8

        @inlinable public 
        init<Integer>(gregorian:Integer) throws where Integer:BinaryInteger
        {
            guard 2020 ..< 2276 ~= gregorian
            else 
            {
                throw YearError<Integer>.gregorian(gregorian)
            }
            self.offset = .init(gregorian - 2020)
        }

        public 
        var gregorian:Int 
        {
            2020 + Int.init(self.offset)
        }
    }
    
    public 
    var year:Year 
    public 
    var month:Component 
    public 
    var day:Component 
    public 
    var hour:UInt8

    @inlinable public 
    init<Component>(year:Year, month:Component, day:Component, hour:UInt8) throws
        where Component:BinaryInteger
    {
        guard 1 ... 12 ~= month 
        else 
        {
            throw ComponentError<Component>.month(month)
        }
        guard 1 ... 31 ~= day 
        else 
        {
            throw ComponentError<Component>.day(day)
        }

        self.year = year
        self.month = .init(.init(month))
        self.day = .init(.init(day)) 
        self.hour = hour
    }
}
extension Date.Component:Comparable 
{
    @inlinable public static 
    func < (lhs:Self, rhs:Self) -> Bool
    {
        lhs.value < rhs.value
    }
}
extension Date.Year:Comparable 
{
    @inlinable public static 
    func < (lhs:Self, rhs:Self) -> Bool
    {
        lhs.offset < rhs.offset
    }
}
extension Date:Comparable 
{
    @inlinable public static 
    func < (lhs:Self, rhs:Self) -> Bool
    {
        (lhs.year, lhs.month, lhs.day, lhs.hour) <
        (rhs.year, rhs.month, rhs.day, rhs.hour)
    }
}
extension Date.Component:CustomStringConvertible 
{
    public 
    var description:String 
    {
        self.value < 10 ? "0\(self.value)" : "\(self.value)"
    }
}
extension Date:CustomStringConvertible 
{
    public 
    var description:String 
    {
        "\(self.year.gregorian)-\(self.month)-\(self.day)-\(Unicode.Scalar.init(self.hour))"
    }
}