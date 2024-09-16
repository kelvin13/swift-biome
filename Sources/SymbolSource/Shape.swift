@frozen public 
enum Shape:Hashable, Comparable, Sendable
{
    @frozen public 
    enum ConcreteType:Sendable, Comparable, Hashable
    {
        case `enum`
        case `struct`
        case `class`
        case  actor
    }
    @frozen public 
    enum Callable:Sendable, Comparable, Hashable
    {
        case `case`
        case  initializer
        case  deinitializer
        case  typeSubscript
        case  instanceSubscript
        case  typeProperty
        case  instanceProperty
        case  typeMethod
        case  instanceMethod
        case  typeOperator
    }
    @frozen public 
    enum Global:Sendable, Comparable, Hashable 
    {
        case `operator`
        case `func`
        case `var`
    }

    case `protocol`
    case `associatedtype`
    case  concretetype(ConcreteType)
    case  callable(Callable)
    case  global(Global)
    case `typealias`
    
    public static 
    let `class`:Self = .concretetype(.class)

    @inlinable public 
    init?(declarationKind:some StringProtocol, global:Bool)
    {
        // https://github.com/apple/swift/blob/main/lib/SymbolGraphGen/Symbol.cpp
        switch declarationKind
        {
            case "swift.protocol":          self = .protocol
            case "swift.associatedtype":    self = .associatedtype
            case "swift.enum":              self = .concretetype(.enum)
            case "swift.struct":            self = .concretetype(.struct)
            case "swift.class":             self = .concretetype(.class)
            case "swift.enum.case":         self = .callable(.case)
            case "swift.init":              self = .callable(.initializer)
            case "swift.deinit":            self = .callable(.deinitializer)
            case "swift.type.subscript":    self = .callable(.typeSubscript)
            case "swift.subscript":         self = .callable(.instanceSubscript)
            case "swift.type.property":     self = .callable(.typeProperty)
            case "swift.property":          self = .callable(.instanceProperty)
            case "swift.type.method":       self = .callable(.typeMethod)
            case "swift.method":            self = .callable(.instanceMethod)
            case "swift.func.op":           self =  global ? .global(.operator) : 
                                                   .callable(.typeOperator)
            case "swift.func":              self = .global(.func)
            case "swift.var":               self = .global(.var)
            case "swift.typealias":         self = .typealias
            default:                        return nil
        }
    }
}
extension Shape:LosslessStringConvertible 
{
    @inlinable public 
    init?(_ string:some StringProtocol)
    {
        switch string 
        {
        case "protocol":        self = .protocol 
        case "associatedtype":  self = .associatedtype 
        case "enum":            self = .concretetype(.enum) 
        case "struct":          self = .concretetype(.struct) 
        case "class":           self = .concretetype(.class) 
        case "actor":           self = .concretetype(.actor) 
        case "enum.case":       self = .callable(.case) 
        case "init":            self = .callable(.initializer) 
        case "deinit":          self = .callable(.deinitializer) 
        case "type.subscript":  self = .callable(.typeSubscript) 
        case "subscript":       self = .callable(.instanceSubscript) 
        case "type.property":   self = .callable(.typeProperty) 
        case "property":        self = .callable(.instanceProperty) 
        case "type.method":     self = .callable(.typeMethod) 
        case "method":          self = .callable(.instanceMethod) 
        case "type.op":         self = .callable(.typeOperator) 
        case "func.op":         self = .global(.operator) 
        case "func":            self = .global(.func) 
        case "var":             self = .global(.var) 
        case "typealias":       self = .typealias 
        default:                return nil
        }
    }
    @inlinable public 
    var description:String
    {
        switch self 
        {
        case .protocol:                     return "protocol"
        case .associatedtype:               return "associatedtype"
        case .concretetype(.enum):          return "enum"
        case .concretetype(.struct):        return "struct"
        case .concretetype(.class):         return "class"
        case .concretetype(.actor):         return "actor"
        case .callable(.case):              return "enum.case"
        case .callable(.initializer):       return "init"
        case .callable(.deinitializer):     return "deinit"
        case .callable(.typeSubscript):     return "type.subscript"
        case .callable(.instanceSubscript): return "subscript"
        case .callable(.typeProperty):      return "type.property"
        case .callable(.instanceProperty):  return "property"
        case .callable(.typeMethod):        return "type.method"
        case .callable(.instanceMethod):    return "method"
        case .callable(.typeOperator):      return "type.op"
        case .global(.operator):            return "func.op"
        case .global(.func):                return "func"
        case .global(.var):                 return "var"
        case .typealias:                    return "typealias"
        }
    }
}
extension Shape:RawRepresentable 
{
    @inlinable public 
    init?(rawValue:Int)
    {
        switch rawValue 
        {
        case  0: self = .protocol
        case  1: self = .associatedtype
        case  2: self = .concretetype(.enum)
        case  3: self = .concretetype(.struct)
        case  4: self = .concretetype(.class)
        case  5: self = .concretetype(.actor)
        case  6: self = .callable(.case)
        case  7: self = .callable(.initializer)
        case  8: self = .callable(.deinitializer)
        case  9: self = .callable(.typeSubscript)
        case 10: self = .callable(.instanceSubscript)
        case 11: self = .callable(.typeProperty)
        case 12: self = .callable(.instanceProperty)
        case 13: self = .callable(.typeMethod)
        case 14: self = .callable(.instanceMethod)
        case 15: self = .callable(.typeOperator)
        case 16: self = .global(.operator)
        case 17: self = .global(.func)
        case 18: self = .global(.var)
        case 19: self = .typealias
        default: return nil
        }
    }
    @inlinable public 
    var rawValue:Int 
    {
        switch self 
        {
        case .protocol:                     return  0
        case .associatedtype:               return  1
        case .concretetype(.enum):          return  2
        case .concretetype(.struct):        return  3
        case .concretetype(.class):         return  4
        case .concretetype(.actor):         return  5
        case .callable(.case):              return  6
        case .callable(.initializer):       return  7
        case .callable(.deinitializer):     return  8
        case .callable(.typeSubscript):     return  9
        case .callable(.instanceSubscript): return 10
        case .callable(.typeProperty):      return 11
        case .callable(.instanceProperty):  return 12
        case .callable(.typeMethod):        return 13
        case .callable(.instanceMethod):    return 14
        case .callable(.typeOperator):      return 15
        case .global(.operator):            return 16
        case .global(.func):                return 17
        case .global(.var):                 return 18
        case .typealias:                    return 19
        }
    }
} 
extension Shape:CaseIterable 
{
    public static 
    let allCases:[Self] = 
    [
        .callable(.case),
        .associatedtype,
        .typealias,
        .callable(.initializer),
        .callable(.deinitializer),
        .callable(.typeSubscript),
        .callable(.instanceSubscript),
        .callable(.typeProperty),
        .callable(.instanceProperty),
        .callable(.typeMethod),
        .callable(.instanceMethod),
        .global(.var),
        .global(.func),
        .global(.operator),
        .callable(.typeOperator),
        .concretetype(.enum),
        .concretetype(.struct),
        .concretetype(.class),
        .concretetype(.actor),
        .protocol,
    ]
}