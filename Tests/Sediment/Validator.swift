import Sediment

struct Validator
{
    let name:String
    var head:Sediment<Int, String>.Head?
    var history:[(Int, String)]
    var counter:Int

    init(name:String)
    {
        self.name = name
        self.head = nil
        self.history = []
        self.counter = 0
    }

    mutating 
    func deposit(to sediment:inout Sediment<Int, String>, time:Range<Int>)
    {
        if .random()
        {
            let token:String = "\(self.name).\(self.counter)"
            self.counter += 1
            self.head = sediment.deposit(token, time: time.lowerBound, over: self.head)
            self.history.append(contentsOf: time.map { ($0, token) })
        }
        else if let token:String = self.history.last?.1 
        {
            self.history.append(contentsOf: time.map { ($0, token) })
        }
    }
    mutating
    func rollback(until time:Int, rollbacks:Sediment<Int, String>.Rollbacks)
    {
        if let index:Int = self.history.firstIndex(where: { time < $0.0 })
        {
            self.history.removeSubrange(index...)
        }
        self.head = self.head.flatMap { rollbacks[$0] }
    }
}