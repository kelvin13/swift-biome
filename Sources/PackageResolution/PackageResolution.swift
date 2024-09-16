import JSON
import SymbolSource

public 
struct PackageResolution:Sendable
{
    public
    var pins:[Pin.ID: Pin]

    public
    init(pins:[Pin])
    {
        self.pins = .init(pins.lazy.map { ($0.id, $0) }) { $1 }
    }
    public 
    init(from json:JSON) throws 
    {
        let pins:[Pin] = try json.lint   
        {
            switch try $0.remove("version", as: Int.self)
            {
            case 1:
                return try $0.remove("object") 
                {
                    try $0.lint 
                    { 
                        try $0.remove("pins", as: [JSON].self) 
                        {
                            try $0.map(Pin.init(from:))
                        }
                    }
                }
            case 2:
                return  try $0.remove("pins", as: [JSON].self)
                {
                            try $0.map(Pin.init(from:))
                }
            default: 
                fatalError("unsupported Package.resolved format") 
            }
        }
        self.init(pins: pins)
    }
    @inlinable public
    init<UTF8>(parsing utf8:UTF8) throws where UTF8:Collection<UInt8>
    {
        try self.init(from: try JSON.init(parsing: utf8))
    }
}
