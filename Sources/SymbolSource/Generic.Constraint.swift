extension Generic.Constraint:Sendable where Target:Sendable {}
extension Generic.Constraint:Hashable where Target:Hashable {}
extension Generic.Constraint:Equatable where Target:Equatable {}

extension Generic 
{
    @frozen public
    enum ConstraintVerb:Int, Hashable, Sendable
    {
        case subclasses = 0 
        case implements 
        case `is`
    }
    @frozen public 
    struct Constraint<Target>
    {
        public 
        var subject:String
        public 
        var verb:ConstraintVerb 
        public 
        var target:Target?
        public 
        var object:String
        
        @inlinable public 
        init(_ subject:String, _ verb:ConstraintVerb, _ object:String, target:Target?)
        {
            self.subject = subject
            self.verb = verb
            self.object = object
            self.target = target
        }
        // right now, this just runs on `target`, but in the future, this monad might 
        // gain another inhabitant...
        @inlinable public 
        func forEach(_ body:(Target) throws -> ()) rethrows 
        {
            let _:Void? = try self.target.map(body)
        }
        @inlinable public
        func map<T>(_ transform:(Target) throws -> T) rethrows -> Constraint<T>
        {
            .init(self.subject, self.verb, self.object, 
                target: try self.target.map(transform))
        }
        @inlinable public
        func flatMap<T>(_ transform:(Target) throws -> T?) rethrows -> Constraint<T>
        {
            .init(self.subject, self.verb, self.object, 
                target: try self.target.flatMap(transform))
        }
    }
}