@_exported import Biome 
import PackageResolution
import PackageCatalogs
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
                let version:MaskedVersion = try? .init(parsing: $0),
                pattern ?= version
            {
                return (directory.appending(component), version)
            }
            else 
            {
                return nil 
            }
        }
        for (project, version):(FilePath, MaskedVersion) in toolchains
        {
            let catalogs:[PackageCatalog] = 
                try .init(parsing: try project.appending("Package.catalog").read())
            
            for catalog:PackageCatalog in catalogs
            {
                try self.updatePackage(catalog.id,
                    graphs: try catalog.modules.map { try $0.load(project: project) }, 
                    brand: catalog.brand,
                    //pins: [.swift: version, .core: version])
                    pins: [:])
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
            
            let resolution:PackageResolution = 
                try .init(parsing: try project.appending("Package.resolved").read())
            let catalogs:[PackageCatalog] = 
                try .init(parsing: try project.appending("Package.catalog").read())
            for catalog:PackageCatalog in catalogs
            {
                try self.updatePackage(catalog.id,
                    graphs: try catalog.modules.map { try $0.load(project: project) }, 
                    brand: catalog.brand,
                    pins: resolution.pins)
            }
        }
        
        self.regenerateCaches()
    }
}
