import SymbolSource 

extension Collection<RawCulturalGraph> 
{
    /// Returns a table of intra-package dependencies. Every constituent culture in
    /// this collection of culturegraphs has an associated entry in this table, even
    /// if it is empty.
    func dependencies(localTo nationality:PackageIdentifier) 
        throws -> [ModuleIdentifier: Set<ModuleIdentifier>]
    {
        var cultures:[ModuleIdentifier: Set<ModuleIdentifier>] = 
            .init(minimumCapacity: self.count)
        
        for culture:RawCulturalGraph in self
        {
            var dependencies:Set<ModuleIdentifier> = []
            for dependency:PackageDependency in culture.dependencies
                where nationality == dependency.nationality
            {
                dependencies.formUnion(dependency.cultures)
            }
            if case _? = cultures.updateValue(dependencies, forKey: culture.id)
            {
                throw SymbolGraphValidationError.duplicateCulturalGraph(culture.id)
            }
        }

        for dependency:ModuleIdentifier in cultures.values.joined()
        {
            guard cultures.keys.contains(dependency)
            else
            {
                throw SymbolGraphValidationError.missingLocalDependency(dependency)
            }
        }
        return cultures
    }
    func topologicallySorted(by dependencies:__owned [ModuleIdentifier: Set<ModuleIdentifier>]) 
        throws -> [RawCulturalGraph]
    {
        var dependencies:[ModuleIdentifier: Set<ModuleIdentifier>] = (_move dependencies).filter
        {
            !$0.value.isEmpty
        }
        var consumers:[ModuleIdentifier: [RawCulturalGraph]] = [:]
        for module:RawCulturalGraph in self
        {
            // need to sort dependency set to make topological sort deterministic
            for dependency:ModuleIdentifier in dependencies[module.id, default: []].sorted()
            {
                consumers[dependency, default: []].append(module)
            }
        }

        var graphs:[RawCulturalGraph] = []
            graphs.reserveCapacity(self.underestimatedCount)
        // perform topological sort
        var sources:[RawCulturalGraph] = self.compactMap 
        {
            dependencies[$0.id, default: []].isEmpty ? $0 : nil
        }
        while let source:RawCulturalGraph = sources.popLast()
        {
            graphs.append(source)

            guard let next:[RawCulturalGraph] = consumers.removeValue(forKey: source.id)
            else 
            {
                continue 
            }
            for next:RawCulturalGraph in next
            {
                guard let index:Dictionary<ModuleIdentifier, Set<ModuleIdentifier>>.Index = 
                    dependencies.index(forKey: next.id)
                else 
                {
                    // already added module to sorted output
                    continue 
                }
                    dependencies.values[index].remove(source.id)
                if  dependencies.values[index].isEmpty 
                {
                    dependencies.remove(at: index)
                    sources.append(next)
                }
            }
        }
        if dependencies.isEmpty, consumers.isEmpty 
        {
            return graphs 
        }
        else 
        {
            throw SymbolGraphValidationError.cyclicLocalDependencies
        }
    }
}
