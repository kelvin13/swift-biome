import PackagePlugin

#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin 
#endif

public
struct ToolError:Error 
{
    public
    enum Stage
    {
        case mkdir
        case posix_spawnp
        case posix_spawn
        case waitpid
        case tool(String)
    }

    public 
    let stage:Stage 
    public 
    let status:Int32

    init(_ stage:Stage, status:Int32)
    {
        self.stage = stage
        self.status = status
    }
}
extension ToolError.Stage:CustomStringConvertible
{
    public 
    var description:String 
    {
        switch self
        {
        case .mkdir:            return "mkdir"
        case .posix_spawnp:     return "posix_spawnp"
        case .posix_spawn:      return "posix_spawn"
        case .waitpid:          return "waitpid"
        case .tool(let tool):   return tool
        }
    }
}
extension ToolError:CustomStringConvertible
{
    public 
    var description:String 
    {
        "\(self.stage.description) exited with code \(self.status)"
    }
}

enum Tool
{
    case executable(Path)
    case command(String)
}
extension Tool
{
    init(_ tool:PluginContext.Tool)
    {
        self = .executable(tool.path)
    }

    var name:String
    {
        switch self
        {
        case .executable(let path):
            return path.lastComponent
        case .command(let name):
            return name
        }
    }
}

extension Tool
{
    func run(arguments:String...) throws
    {
        try self.run(arguments: arguments)
    }
    func run(arguments:[String]) throws
    {
        let first:String
        switch self
        {
        case .executable(let path):
            first = path.string
        case .command(let name):
            first = name
        }
        try first.withCString 
        {
            (first:UnsafePointer<CChar>) in 

            let arguments:[UnsafeMutablePointer<CChar>] = arguments.map
            {
                let bytes:Int = $0.utf8.count
                let argument:UnsafeMutablePointer<CChar> = .allocate(capacity: bytes + 1)
                for (offset, byte):(Int, UInt8) in $0.utf8.enumerated()
                {
                    (argument + offset).initialize(to: Int8.init(bitPattern: byte))
                }
                (argument + bytes).initialize(to: 0)
                return argument
            }
            defer
            {
                arguments.map { $0.deallocate() }
            }

            // must be null-terminated!
            let vector:[UnsafeMutablePointer<CChar>?] = 
            [
                .init(mutating: first),
            ]
            +
            arguments.lazy.map(Optional.some(_:))
            +
            [
                nil
            ]

            var pid:pid_t = 0
            if case .command = self
            {
                switch posix_spawnp(&pid, first, nil, nil, vector, nil)
                {
                case 0: 
                    break 
                case let code: 
                    throw ToolError.init(.posix_spawnp, status: code)
                }
            }
            else
            {
                switch posix_spawn(&pid, first, nil, nil, vector, nil)
                {
                case 0: 
                    break 
                case let code: 
                    throw ToolError.init(.posix_spawn, status: code)
                }
            }
            
            var status:Int32 = 0
            switch waitpid(pid, &status, 0)
            {
            case pid: 
                break 
            case let code:
                throw ToolError.init(.waitpid, status: code)
            }
            guard status == 0 
            else 
            {
                throw ToolError.init(.tool(self.name), status: status)
            }
        }
    }
}

extension Path
{
    func makeDirectory() throws
    {
        switch mkdir(self.string, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH)
        {
        case 0:
            break
        case let code:
            throw ToolError.init(.mkdir, status: code)
        }
    }
}
