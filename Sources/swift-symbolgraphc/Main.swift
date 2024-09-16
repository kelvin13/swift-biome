@preconcurrency import SystemExtras
import ArgumentParser

import SymbolGraphCompiler
import SymbolGraphs

@main 
struct Main:AsyncParsableCommand 
{
    static 
    var configuration:CommandConfiguration = .init(
        abstract: "compile swift symbolgraphs")
    
    @Flag(name: [.customShort("v"), .customLong("verbose")], 
        help: "emit verbose output")
    var verbose:Bool = false
    @Option(name: [.customShort("j"), .customLong("threads")], 
        help: "maximum number of threads to use")
    var threads:Int = 8
    @Argument(help: "build description(s)")
    var builds:String
    
    static 
    func main() async 
    {
        do 
        {
            let command:Self = try Self.parseAsRoot() as! Self
            try await command.run()
        } 
        catch 
        {
            exit(withError: error)
        }
    }
    
    func run() async throws 
    {
        let builds:[Build] = try .init(parsing: self.builds.utf8)

        try await withThrowingTaskGroup(of: (String, FilePath).self)
        {
            (queue:inout ThrowingTaskGroup<(String, FilePath), Error>) in

            var width:Int = 0
            for build:Build in builds
            {
                try Task.checkCancellation() 
                
                let graph:RawSymbolGraph = try .init(loading: build, relativeTo: nil)

                if width < self.threads
                {
                    width += 1
                }
                else if let (ss, output):(String, FilePath) = try await queue.next() 
                {
                    try output.write(ss)
                }
                queue.addTask 
                {
                    var diagnostics:[Diagnostic]? = self.verbose ? [] : nil
                    let compiled:SymbolGraph = try .init(compiling: graph, 
                        diagnostics: &diagnostics)
                    for diagnostic:Diagnostic in diagnostics ?? []
                    {
                        print(diagnostic)
                    }
                    let output:FilePath = .init("\(compiled.id).ss")
                    return (compiled.serialized.description, output)
                }
            }
            for try await (ss, output):(String, FilePath) in queue 
            {
                try output.write(ss)
                print("emitted symbolgraph '\(output.string)' (\(ss.utf8.count >> 10) KiB)")
            }
        }
    }
}