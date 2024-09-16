import Testing

@main 
enum Main:SyncTests
{
    static 
    func run(tests:Tests)
    {
        for i:Int in 0 ..< 500
        {
            print("performing fuzzing iteration \(i)")
            TestSediment(tests / i.description)
        }
    }
}
