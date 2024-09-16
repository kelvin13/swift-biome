extension Module
{
    struct Metadata:Equatable, Sendable 
    {
        let dependencies:Set<Module>

        init(dependencies:Set<Module>)
        {
            self.dependencies = dependencies
        }
    }
}