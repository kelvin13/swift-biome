import PackagePlugin

public
struct InvalidOptionValueError:Error
{
    public 
    let option:String
    public 
    let value:String
    public 
    let message:String

    init(option:String, value:String, message:String = "")
    {
        self.option = option
        self.value = value
        self.message = message
    }
}
extension InvalidOptionValueError:CustomStringConvertible
{
    public
    var description:String 
    {
        """
        invalid value '\(self.value)' for option '\(self.option)'\
        \(self.message.isEmpty ? "" : ": \(self.message)")
        """
    }
}
public
struct MissingOptionValueError:Error
{
    public 
    let option:String
}
extension MissingOptionValueError:CustomStringConvertible
{
    public
    var description:String 
    {
        "option '\(self.option)' expects a value"
    }
}
public
struct MissingNationalityError:Error 
{
    public
    let name:Package.ID
    public 
    init(name:Package.ID)
    {
        self.name = name 
    }
}
extension MissingNationalityError:CustomStringConvertible
{
    public 
    var description:String 
    {
        "nationality '\(self.name)' contributed no cultures to the symbolgraph"
    }
}
public
struct MissingCultureError:Error 
{
    public
    let name:String
    public 
    init(name:String)
    {
        self.name = name 
    }
}
extension MissingCultureError:CustomStringConvertible
{
    public 
    var description:String 
    {
        "culture '\(self.name)' is not a swift source module in this package"
    }
}

enum KnownCulture:String
{
    case Swift
    case _Concurrency
    case _Differentiation
    case Distributed
    case RegexBuilder
    case _RegexParser
    case _StringProcessing

    case Dispatch
    case Foundation
}
extension KnownCulture
{
    var localDependencies:[Self]
    {
        switch self
        {
        case .Swift:
            return []
        
        case ._Concurrency: 
            return [.Swift]
        
        case ._Differentiation: 
            return [.Swift]
        
        case .Distributed: 
            return [.Swift, ._Concurrency]
        
        case .RegexBuilder: 
            return [.Swift, ._RegexParser, ._StringProcessing]
        
        case ._RegexParser: 
            return [.Swift]
        
        case ._StringProcessing: 
            return [.Swift, ._RegexParser]
        
        case .Dispatch:
            return []
        
        case .Foundation: 
            return [.Dispatch]
        }
    }
}
extension KnownCulture:CustomStringConvertible
{
    var description:String
    {
        self.rawValue
    }
}

struct Filter
{
    private
    var nationalities:Set<Package.ID>
    private
    var cultures:Set<String>
    private(set)
    var toolchain:Tool?
    private(set)
    var deadnames:[KnownCulture: String?]
    private(set)
    var verbose:Bool

    init(parsing arguments:[String]) throws
    {
        self.nationalities = []
        self.cultures = []
        self.toolchain = nil
        self.deadnames = [:]
        self.verbose = false

        var iterator:Array<String>.Iterator = arguments.makeIterator()
        while let argument:String = iterator.next()
        {
            switch argument
            {
            case "-v", "-verbose", "--verbose":
                self.verbose = true
            
            case "-s", "-swift", "--swift":
                switch iterator.next()
                {
                case nil:
                    throw MissingOptionValueError.init(option: argument)
                
                case "swift"?:
                    self.toolchain = .command("swift")
                case let path?:
                    self.toolchain = .executable(.init(path))
                }
            
            case "-d", "-swift-deadnames", "--swift-deadnames":
                guard let expression:String = iterator.next()
                else
                {
                    throw MissingOptionValueError.init(option: argument)
                }
                for mapping:Substring in expression.split(separator: ",")
                {
                    let mapping:[Substring] = mapping.split(separator: ":")
                    guard let culture:KnownCulture = .init(rawValue: .init(mapping[0]))
                    else
                    {
                        throw InvalidOptionValueError.init(option: argument, value: expression,
                            message: "\(mapping[0]) is not a valid standard- or core-library culture")
                    }
                    if      mapping.count == 1
                    {
                        self.deadnames[culture] = .some(nil)
                    }
                    else if mapping.count == 2
                    {
                        self.deadnames[culture] = .init(mapping[1])
                    }
                    else
                    {
                        throw InvalidOptionValueError.init(option: argument, value: expression)
                    }
                }

            case "-n", "-nationality", "--nationality":
                if  let nationality:String = iterator.next()?.lowercased()
                {
                    self.nationalities.insert(nationality as Package.ID)
                }
                else
                {
                    throw MissingOptionValueError.init(option: argument)
                }
            
            case let culture:
                self.cultures.insert(culture)
            }
        }
    }

    func matches(nationality:Package.ID) -> Bool
    {
        self.nationalities.isEmpty ? true : self.nationalities.contains(nationality)
    }
    func matches(culture:String) -> Bool
    {
        self.cultures.contains(culture)
    }

    func validate(_ found:[Module<SwiftSourceModuleTarget>]) throws
    {
        var nationalities:Set<Package.ID> = self.nationalities
        var cultures:Set<String> = self.cultures
        for culture:Module<SwiftSourceModuleTarget> in found
        {
            nationalities.remove(culture.nationality)
            cultures.remove(culture.target.name)
        }

        if let missing:String = nationalities.first 
        {
            throw MissingNationalityError.init(name: missing)
        }
        if let missing:String = cultures.first 
        {
            throw MissingCultureError.init(name: missing)
        }
    }
}
    
@main 
struct Main:CommandPlugin
{
    func performCommand(context:PluginContext, arguments:[String]) throws 
    {
        let filter:Filter = try .init(parsing: arguments)
        let symbolgraphc:Tool = .init(try context.tool(named: "swift-symbolgraphc"))

        var builds:[Build]
        if let swift:Tool = filter.toolchain
        {
            builds = try self.builds(context: context, filter: filter, toolchain: swift)
        }
        else
        {
            builds = []
        }

        builds.append(contentsOf: try self.builds(context: context, filter: filter))

        let serialized:String = "[\(builds.lazy.map(\.description).joined(separator: ", "))]"
        try symbolgraphc.run(arguments: filter.verbose ? [serialized, "-v"] : [serialized])
    }
    func builds(context:PluginContext, filter:Filter, toolchain swift:Tool) throws -> [Build]
    {
        let rm:Tool = .command("rm")

        print("generating symbolgraphs for toolchain:")
        try swift.run(arguments: "--version")

        var builds:[Build] = []
        for (nationality, cultures):(Package.ID, [KnownCulture]) in 
        [
            (
                "swift-standard-library",
                [
                    .Swift,
                    ._Concurrency,
                    ._Differentiation,
                    .Distributed,
                    .RegexBuilder,
                    ._RegexParser,
                    ._StringProcessing,
                ]
            ),
            (
                "swift-core-libraries",
                [
                    .Dispatch,
                    .Foundation,
                ]
            ),
        ]
        {
            let directory:Path = context.pluginWorkDirectory.appending(nationality)
            try rm.run(arguments: "-rf", directory.string)
            try directory.makeDirectory()

            let cultures:[Build.Culture] = try cultures.compactMap
            {
                guard let name:String = filter.deadnames[$0, default: $0.description]
                else
                {
                    return nil as Build.Culture?
                }
                let dependencies:Build.Dependency = .init(nationality: nationality, 
                    cultures: $0.localDependencies.compactMap
                    {
                        filter.deadnames[$0, default: $0.description]
                    })

                let directory:Path = directory.appending($0.description)
                try directory.makeDirectory()
                // TODO: use a native target on macOS instead of a linux target everywhere
                try swift.run(arguments: "symbolgraph-extract",
                    "-target", "x86_64-unknown-linux-gnu",
                    "-output-dir", directory.string,
                    "-module-name", name)
                
                return .init(id: name, dependencies: [dependencies], include: [directory])
            }

            builds.append(.init(id: nationality, cultures: cultures))
        }
        return builds
    }
    func builds(context:PluginContext, filter:Filter) throws -> some Sequence<Build>
    {
        // determine which products belong to which packages 
        let graph:PackageGraph = .init(context.package)
        #if swift(>=5.7)
        var snippets:[Module<SwiftSourceModuleTarget>] = []
        #endif
        var cultures:[Module<SwiftSourceModuleTarget>] = []

        var seen:Set<Target.ID> = []
        for target:any Target in graph.local.targets 
        {
            graph.walk(target)
            {
                guard   filter.matches(nationality: $0.nationality),
                        let target:SwiftSourceModuleTarget = $0.target as? SwiftSourceModuleTarget, 
                        case nil = seen.update(with: $0.target.id)
                else 
                {
                    return 
                }
                let module:Module<SwiftSourceModuleTarget> = .init(target, in: $0.nationality)

                #if swift(>=5.7)
                if case .snippet = target.kind 
                {
                    snippets.append(module)
                    return
                }
                #endif
                if filter.matches(culture: $0.target.name)
                {
                    cultures.append(module)
                }
            }
        }
        
        try filter.validate(cultures)

        let options:PackageManager.SymbolGraphOptions = .init(
            minimumAccessLevel: .public,
            includeSynthesized: true,
            includeSPI: true)
        
        var added:Set<Target.ID> = []
        var builds:[Package.ID: Build] = [:]
        for culture:Module<SwiftSourceModuleTarget> in cultures 
        {
            let implicit:[Package.ID: [SwiftSourceModuleTarget]] = 
                graph.dependencies(of: culture)
            
            for (nationality, targets):(Package.ID, [SwiftSourceModuleTarget]) in 
                [(culture.nationality, [culture.target])] + implicit
            {
                for target:SwiftSourceModuleTarget in targets
                {
                    guard case nil = added.update(with: target.id), 
                        filter.matches(nationality: nationality)
                    else
                    {
                        continue
                    }

                    let dependencies:[Package.ID: [SwiftSourceModuleTarget]]
                    if target.id == culture.target.id
                    {
                        dependencies = implicit
                    }
                    else
                    {
                        print("generating colonial graphs for implicitly included culture '\(target.name)'")
                        dependencies = graph.dependencies(of: .init(target, in: nationality))
                    }

                    let graphs:PackageManager.SymbolGraphResult = 
                        try self.packageManager.getSymbolGraph(for: target, options: options)
                    var include:[Path] = [graphs.directoryPath]
                    for file:File in target.sourceFiles
                    {
                        if  case .unknown = file.type, 
                            case "docc"?  = file.path.extension?.lowercased()
                        {
                            include.append(file.path)
                        }
                    }
                    
                    builds[nationality, default: .init(id: nationality)].cultures.append(
                        .init(id: target.name, 
                            dependencies: dependencies.map(Build.Dependency.init(_:)),
                            include: include))
                }
            }
        }
        #if swift(>=5.7)
        for snippet:Module<SwiftSourceModuleTarget> in snippets
        {
            let sources:[Path] = snippet.target.sourceFiles.compactMap 
            {
                if case .source = $0.type 
                {
                    return $0.path
                }
                else 
                {
                    return nil 
                }
            }
            builds[snippet.nationality, default: .init(id: snippet.nationality)].snippets.append(
                .init(id: snippet.target.name, 
                    dependencies: graph.dependencies(of: snippet).map(Build.Dependency.init(_:)), 
                    sources: sources))
        }
        #endif

        return builds.values
    }
}