import PackagePlugin

struct PackageGraph 
{
    let local:Package
    private 
    var table:[Product.ID: Package.ID] 

    init(_ package:Package) 
    {
        self.local = package 
        self.table = [:]
        self.update(with: package)
    }

    subscript(product:Product.ID) -> Package.ID 
    {
        self.table[product] ?? self.local.id
    }

    private mutating 
    func update(with package:Package) 
    {
        for dependency:PackageDependency in package.dependencies 
        {
            self.update(with: dependency.package)
        }
        for product:any Product in package.products
        {
            switch self.table.updateValue(package.id, forKey: product.id)
            {
            case nil, package.id?:
                break 
            case _?:
                fatalError("duplicate products named '\(product.id)'")
            }
        }
    }

    func dependencies<SomeTarget>(of module:Module<SomeTarget>) -> [Package.ID: [SomeTarget]]
        where SomeTarget:Target 
    {
        var dependencies:[Package.ID: [SomeTarget]] = [:]
        var seen:Set<Target.ID> = []
        self.walkDependencies(of: .init(module.target, in: module.nationality))
        {
            // package.origin is always set to .root, and never contains 
            // useful version information.
            if  let target:SomeTarget = $0.target as? SomeTarget, 
                case nil = seen.update(with: target.id)
            {
                dependencies[$0.nationality, default: []].append(target)
            }
        }
        return dependencies
    }

    func walk(_ target:any Target, _ body:(Module<any Target>) throws -> ()) rethrows
    {
        try self.walk(.init(target, in: self.local.id), body)
    }
    func walk(_ module:Module<any Target>, _ body:(Module<any Target>) throws -> ()) rethrows
    {
        try body(module)
        try self.walkDependencies(of: module, body)
    }
    private
    func walkDependencies(of module:Module<any Target>, _ body:(Module<any Target>) throws -> ())
        rethrows
    {
        for dependency:TargetDependency in module.target.dependencies 
        {
            switch dependency 
            {
            case .target(let target): 
                let module:Module<any Target> = .init(target, in: module.nationality)
                try self.walk(module, body)
            
            case .product(let product): 
                let package:Package.ID = self[product.id]
                for target:any Target in product.targets 
                {
                    let module:Module<any Target> = .init(target, in: package)
                    try self.walk(module, body)
                }
            }
        }
    }
}