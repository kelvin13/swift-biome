import Forest 

infix operator ==? :ComparisonPrecedence
infix operator ..? :ComparisonPrecedence

struct OptionalUnwrapFailure<Wrapped>:Error, CustomStringConvertible 
{
    var description:String
    {
        """
        expected non-nil value of type \(Wrapped.self)
        """
    }
}
struct AssertionFailure:Error, CustomStringConvertible 
{
    var description:String
    {
        """
        expected true
        """
    }
}
struct AssertEquivalenceFailure<T>:Error, CustomStringConvertible  
{
    let lhs:T
    let rhs:T

    var description:String
    {
        """
        expected equal values: 
        {
            lhs: \(lhs),
            rhs: \(rhs)
        }
        """
    }
}
func ..? <LHS, RHS>(lhs:LHS, rhs:RHS) -> AssertEquivalenceFailure<[LHS.Element]>?
    where LHS:Sequence, RHS:Sequence, LHS.Element == RHS.Element, LHS.Element:Equatable
{
    let rhs:[LHS.Element] = .init(rhs)
    let lhs:[LHS.Element] = .init(lhs)
    if  lhs.elementsEqual(rhs) 
    {
        return nil 
    }
    else 
    {
        return .init(lhs: lhs, rhs: rhs)
    }
}
func ==? <T>(lhs:T, rhs:T) -> AssertEquivalenceFailure<T>?
    where T:Equatable
{
    if  lhs == rhs
    {
        return nil 
    }
    else 
    {
        return .init(lhs: lhs, rhs: rhs)
    }
}

@main 
struct Main 
{
    mutating 
    func assert<T>(_ error:AssertEquivalenceFailure<T>?, 
        file:String = #file, 
        function:String = #function, 
        line:Int = #line, 
        column:Int = #column) 
    {
        if let error:AssertEquivalenceFailure<T>
        {
            print("\(file):\(line):\(column): \(error)")
            self.failed.append(error)
        }
        else 
        {
            self.passed += 1
        }
    }
    mutating 
    func assert(_ test:Bool, 
        file:String = #file, 
        function:String = #function, 
        line:Int = #line, 
        column:Int = #column)  
    {
        if test 
        {
            self.passed += 1
        }
        else
        {
            print("\(file):\(line):\(column): test failed")
            self.failed.append(AssertionFailure.init())
        }
    }
    func unwrap<Wrapped>(_ optional:Wrapped?, 
        file:String = #file, 
        function:String = #function, 
        line:Int = #line, 
        column:Int = #column) -> Wrapped?
    {
        if let wrapped:Wrapped = optional
        {
            return wrapped 
        }
        else 
        {
            print("\(file):\(line):\(column): optional unwrap failed")
            return nil
        }
    }

    var passed:Int 
    var failed:[any Error]

    init() 
    {
        self.passed = 0
        self.failed = []
    }

    static 
    func main() 
    {
        var tests:Self = .init()
            tests.main()
        print("passed: \(tests.passed)")
        print("failed: \(tests.failed.count)")
    }
    mutating 
    func main() 
    {
        self.testBisection()

        self.test(inserting:  0 ..< 256,             removing:  0 ..< 256)
        self.test(inserting:  0 ..< 256,             removing: (0 ..< 256).reversed())
        self.test(inserting: (0 ..< 256).reversed(), removing: (0 ..< 256))
        self.test(inserting: (0 ..< 256).reversed(), removing: (0 ..< 256).reversed())

        self.test(inserting: [1, 2, 0], removing: [1, 2, 0])
        self.test(inserting: [1, 2, 0], removing: [0, 1, 2])
        self.test(inserting: [1, 2, 0], removing: [2, 1, 0])

        self.test(inserting: (0 ..< 1024).shuffled(), removing: (0 ..< 1024).shuffled())
    }
    mutating 
    func test(inserting insertions:some Sequence<Int>, removing removals:some Sequence<Int>) 
    {
        let insertions:[Int] = .init(insertions)
        let sorted:[Int] = insertions.sorted()
        var forest:Forest<Int> = .init()
        var tree:Forest<Int>.Tree.Head? = nil
        for element:Int in insertions 
        {
            forest.insert(element, into: &tree)
        }

        self.assert(forest.count ==? sorted.count)
        self.assert(forest[tree] ..? sorted)
        self.assert(forest[tree].validate())

        for element:Int in removals
        {
            if let index:Forest<Int>.Index = self.unwrap(forest[tree].find(element))
            {
                forest.remove(index, from: &tree)
                self.assert(forest[tree].validate())
            }
        }

        self.assert(forest._inhabitants() ==? 0)
    }
    mutating 
    func testBisection() 
    {
        var forest:Forest<(Int, Unicode.Scalar)> = .init()
        var tree:Forest<(Int, Unicode.Scalar)>.Tree.Head 

        tree = forest.insert((0xA, "c"))
        tree = forest.insert((0x4, "b"), before: tree)
        tree = forest.insert((0x3, "a"), before: tree)

        let results:[Unicode.Scalar?] = (0x0 ... 0xB).map 
        {
            (x:Int) in 
            if  let index:Forest<(Int, Unicode.Scalar)>.Index = 
                    forest[tree].first(where: { $0.0 >= x })
            {
                return forest[index].value.1
            }
            else 
            {
                return nil 
            }
        }
        self.assert(results ..? ["a", "a", "a", "a", "b", "c", "c", "c", "c", "c", "c", nil])
    }
}