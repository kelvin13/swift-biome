struct PackageImpact
{
    let dependencies:[Package: (version:Version, consumers:Set<Module>)]
    let version:Version

    init(interface:PackageInterface)
    {
        self.version = interface.version 
        self.dependencies = interface.reduce(into: [:]) 
        { 
            for dependency:Package in $1.context.upstream.keys 
            {
                $0[dependency, default: (interface.version, [])].consumers.insert($1.culture)
            }
        }
    }
}