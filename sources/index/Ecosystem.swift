@_exported import Biome 
import SystemExtras

extension Ecosystem 
{
    public mutating 
    func loadToolchains(from directory:FilePath, 
        matching pattern:MaskedVersion? = nil) throws 
    {
        try Task.checkCancellation() 
        
        let available:String = try directory.appending("swift-versions").read()
        let toolchains:[(path:FilePath, version:MaskedVersion)] = available
            .split(whereSeparator: \.isWhitespace)
            .compactMap 
        {
            if  let component:FilePath.Component = .init(String.init($0)), 
                let version:MaskedVersion = .init($0),
                pattern ?= version
            {
                return (directory.appending(component), version)
            }
            else 
            {
                return nil 
            }
        }
        for (project, version):(FilePath, MaskedVersion) in toolchains.dropFirst()
        {
            let catalogs:[Package.Catalog] = 
                try .init(parsing: try project.appending("Package.catalog").read())
            
            for catalog:Package.Catalog in catalogs
            {
                try self.updatePackage(try catalog.loadGraph(relativeTo: project), 
                    pins: [.swift: version, .core: version])
            }
        }
    }
    public mutating  
    func loadProjects(from projects:[FilePath]) throws
    {
        for project:FilePath in projects 
        {
            try Task.checkCancellation() 
            
            print("loading project '\(project)'...")
            
            let resolved:Package.Resolved = 
                try .init(parsing: try project.appending("Package.resolved").read())
            let catalogs:[Package.Catalog] = 
                try .init(parsing: try project.appending("Package.catalog").read())
            for catalog:Package.Catalog in catalogs
            {
                try self.updatePackage(try catalog.loadGraph(relativeTo: project), 
                    pins: resolved.pins)
            }
        }
        
        self.regenerateCaches()
    }
}
