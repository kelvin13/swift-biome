import SymbolSource 

extension Branch 
{
    struct SymbolTraits:Equatable, Sendable
    {
        /// if a concrete type, the members of this type, not including members 
        /// inherited through protocol conformances. 
        /// if a protocol, the members in extensions of this protocol. 
        /// 
        /// requirements and witnesses must not access this property.
        var members:Set<Symbol>
        
        /// if a protocol, protocols that inherit from this protocol.
        /// if a class, classes that subclass this class.
        /// if a requirement, any requirements of protocols that refine its
        /// interface that also restate this requirement.
        /// if a witness, any subclass members that override this witness, if 
        /// it is a class member.
        var downstream:Set<Symbol>
        
        //private 
        var unconditional:Set<Symbol>
        /// if a concrete type, members of this type inherited through 
        /// protocol conformances.
        /// 
        /// this shares backing storage with ``implementations``. requirements 
        /// should access ``implementations`` instead. protocols and witnesses 
        /// must not access this property.
        /// 
        /// > note: for concrete types, the module that an inherited member 
        /// originates from is not necessarily the perpetrator of the conformance 
        /// that trafficked it into its scope.
        var features:Set<Symbol>
        {
            _read 
            {
                yield self.unconditional
            }
            _modify
            {
                yield &self.unconditional
            }
        }
        
        /// if a requirement, the default implementations available for this 
        /// requirement. 
        /// 
        /// this shares backing storage with ``features``. types and witnesses 
        /// must not access this property.
        var implementations:Set<Symbol>
        {
            _read 
            {
                yield self.unconditional
            }
            _modify
            {
                yield &self.unconditional
            }
        }

        //private 
        var conditional:[Symbol: [Generic.Constraint<Symbol>]]
        /// if a protocol, concrete types that implement this protocol.
        /// 
        /// this shares backing storage with ``conformances``. concrete types 
        /// should access ``conformances`` instead. requirements and witnesses 
        /// must not access this property.
        var conformers:[Symbol: [Generic.Constraint<Symbol>]]
        {
            _read 
            {
                yield self.conditional
            }
            _modify
            {
                yield &self.conditional
            }
        }
        /// if a concrete type, protocols this type conforms to.
        /// 
        /// this shares backing storage with ``conformers``. protocols 
        /// should access ``conformers`` instead. requirements and witnesses 
        /// must not access this property.
        var conformances:[Symbol: [Generic.Constraint<Symbol>]]
        {
            _read 
            {
                yield self.conditional
            }
            _modify
            {
                yield &self.conditional
            }
        }
        
        init(members:Set<Symbol> = [],
            downstream:Set<Symbol> = [],
            unconditional:Set<Symbol> = [],
            conditional:[Symbol: [Generic.Constraint<Symbol>]] = [:]) 
        {
            self.members = members
            self.downstream = downstream
            self.unconditional = unconditional
            self.conditional = conditional
        }
    }
}