import SymbolGraphs
import SymbolSource

struct SurfaceValidationError:Error
{
}

extension SurfaceBuilder
{
    struct Belief 
    {
        enum Predicate 
        {
            case `is`(Role<AtomicPosition<Symbol>>)
            case has(Trait)
        }

        let subject:AtomicPosition<Symbol>
        let predicate:Predicate

        init(_ subject:AtomicPosition<Symbol>, _ predicate:Predicate)
        {
            self.subject = subject 
            self.predicate = predicate
        }
    }
}
extension SurfaceBuilder
{
    enum Beliefs
    {
        case one(Belief)
        case two(Belief, Belief)
    }
}
extension RangeReplaceableCollection<SurfaceBuilder.Belief>
{
    mutating 
    func append(contentsOf beliefs:__owned SurfaceBuilder.Beliefs)
    {
        switch beliefs
        {
        case .two(let source, let target):
            self.append(source)
            fallthrough
        case .one(let target):
            self.append(target)
        }
    }
}
extension SurfaceBuilder.Beliefs
{
    init(edge:SymbolGraph.Edge<AtomicPosition<Symbol>>, source:Shape, target:Shape) throws
    {
        switch (source, edge.source, is: edge.relation, of: target, edge.target) 
        {
        case    (.callable, let source, is: .feature, of: .concretetype, let target):
            self = .one(.init(target, .has(.feature(source))))
        
        case    (.concretetype, let source, is: .member,    of: .concretetype,  let target), 
                (.typealias,    let source, is: .member,    of: .concretetype,  let target), 
                (.callable,     let source, is: .member,    of: .concretetype,  let target), 
                (.concretetype, let source, is: .member,    of: .protocol,      let target),
                (.typealias,    let source, is: .member,    of: .protocol,      let target),
                (.callable,     let source, is: .member,    of: .protocol,      let target):
            self = .two(
                .init(source,  .is(.member(of: target))), 
                .init(target, .has(.member(    source))))
        
        case    (.concretetype, let source, is: .conformer(let constraints), of: .protocol, let target):
            self = .two(
                .init(source, .has(.conformance(target, where: constraints))), 
                .init(target, .has(  .conformer(source, where: constraints))))
         
        case    (.protocol, let source, is: .conformer([]), of: .protocol, let target):
            self = .two(
                .init(source,  .is(.refinement(of: target))), 
                .init(target, .has(.refinement(    source))))
        
        case    (.class, let source, is: .subclass, of: .class, let target):
            self = .two(
                .init(source,  .is(.subclass(of: target))), 
                .init(target, .has(.subclass(    source))))
         
        case    (.associatedtype,   let source, is: .override, of: .associatedtype, let target),
                (.callable,         let source, is: .override, of: .callable,       let target):
            self = .two(
                .init(source,  .is(.override(of: target))), 
                .init(target, .has(.override(    source))))
         
        case    (.associatedtype,   let source, is:         .requirement, of: .protocol, let target),
                (.callable,         let source, is:         .requirement, of: .protocol, let target),
                (.associatedtype,   let source, is: .optionalRequirement, of: .protocol, let target),
                (.callable,         let source, is: .optionalRequirement, of: .protocol, let target):
            self = .two(
                .init(source,  .is(.requirement(of: target))), 
                .init(target,  .is(  .interface(of: source))))
         
        case    (.callable, let source, is: .defaultImplementation, of: .callable, let target):
            self = .two(
                .init(source,  .is(.implementation(of: target))), 
                .init(target, .has(.implementation(    source))))
        
        default:
            throw SurfaceValidationError.init()
        }
    }
}