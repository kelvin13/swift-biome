import BiomeABI
import MongoDB
import NIOCore

public
struct Database
{
    // private
    // let database:MongoDatabase
    // private
    // let surfaces:MongoCollection<BSONDocument>

    // init(client:MongoClient) async throws 
    // {
    //     self.database = client.db("biome")
    //     self.surfaces = try await self.database.createCollection("surfaces")
    // }
    public
    init()
    {
    }
}
extension Database
{
    public
    func loadSurface(for nationality:Package, version:Version) async throws -> Surface 
    {
        fatalError("unimplemented")
    }

    public
    func storeSurface(_ surface:Surface, 
        for nationality:Package, 
        version:Version) async throws
    {
        // try await self.surfaces.updateOne(filter: 
        // [
        //     "_id": 0,
        // ], 
        // update: 
        // [
        //     "surface": 
        //     [
        //         "$set": .binary(.init(buffer: surface.serialized(), subtype: .generic)),
        //     ],
        // ])
        fatalError("unimplemented")
    }

    // func storeDocumentation(_ literature:PackageDocumentation) async throws
    // {
    //     fatalError("unimplemented")
    // }
}

extension Surface
{
    enum DeserializationError:Error
    {
        case headers
        case article(at:Int)
        case symbol(at:Int)
        case module(at:Int)
        case overlay(at:Int)
    }

    init(reading buffer:inout ByteBuffer) throws
    {
        guard   let articles:Int = buffer.readInteger(endianness: .little),
                let symbols:Int = buffer.readInteger(endianness: .little),
                let modules:Int = buffer.readInteger(endianness: .little),
                let overlays:Int = buffer.readInteger(endianness: .little)
        else
        {
            throw DeserializationError.headers
        }

        self.init()
        self.articles.reserveCapacity(articles)
        self.symbols.reserveCapacity(symbols)
        self.modules.reserveCapacity(modules)
        self.overlays.reserveCapacity(overlays)

        for index:Int in 0 ..< articles
        {
            if let article:Article = buffer.readArticle()
            {
                self.articles.append(article)
            }
            else
            {
                throw DeserializationError.article(at: index)
            }
        }
        for index:Int in 0 ..< symbols
        {
            if let symbol:Symbol = buffer.readSymbol()
            {
                self.symbols.append(symbol)
            }
            else
            {
                throw DeserializationError.symbol(at: index)
            }
        }
        for index:Int in 0 ..< modules
        {
            if let module:Module = buffer.readModule()
            {
                self.modules.append(module)
            }
            else
            {
                throw DeserializationError.module(at: index)
            }
        }
        for index:Int in 0 ..< overlays
        {
            if let overlay:Diacritic = buffer.readDiacritic()
            {
                self.overlays.append(overlay)
            }
            else
            {
                throw DeserializationError.overlay(at: index)
            }
        }
    }

    func serialized() -> ByteBuffer
    {
        var buffer:ByteBuffer = .init()
        self.serialized(writing: &buffer)
        return buffer
    }
    func serialized(writing buffer:inout ByteBuffer)
    {
        buffer.reserveCapacity(minimumWritableBytes: 4 * MemoryLayout<Int>.size +
            self.articles.count * MemoryLayout<Article>.size +
            self.symbols.count * MemoryLayout<Symbol>.size +
            self.modules.count * MemoryLayout<Module>.size +
            self.overlays.count * MemoryLayout<Diacritic>.size)
        
        buffer.writeInteger(self.articles.count, endianness: .little)
        buffer.writeInteger(self.symbols.count, endianness: .little)
        buffer.writeInteger(self.modules.count, endianness: .little)
        buffer.writeInteger(self.overlays.count, endianness: .little)
        for article:Article in self.articles
        {
            buffer.writeArticle(article)
        }
        for symbol:Symbol in self.symbols
        {
            buffer.writeSymbol(symbol)
        }
        for module:Module in self.modules
        {
            buffer.writeModule(module)
        }
        for overlay:Diacritic in self.overlays
        {
            buffer.writeDiacritic(overlay)
        }
    }
}

extension ByteBuffer
{
    mutating
    func readPackage() -> Package?
    {
        self.readInteger(endianness: .little).map(Package.init(offset:))
    }
    mutating
    func writePackage(_ package:Package)
    {
        self.writeInteger(package.offset, endianness: .little)
    }
}
extension ByteBuffer
{
    mutating
    func readModule() -> Module?
    {
        if  let nationality:Package = self.readPackage(),
            let offset:UInt16 = self.readInteger(endianness: .little)
        {
            return .init(nationality, offset: offset)
        }
        else
        {
            return nil
        }
    }
    mutating
    func writeModule(_ module:Module)
    {
        self.writePackage(module.nationality)
        self.writeInteger(module.offset, endianness: .little)
    }
}
extension ByteBuffer
{
    mutating
    func readSymbol() -> Symbol?
    {
        if  let culture:Module = self.readModule(),
            let offset:UInt32 = self.readInteger(endianness: .little)
        {
            return .init(culture, offset: offset)
        }
        else
        {
            return nil
        }
    }
    mutating
    func writeSymbol(_ symbol:Symbol)
    {
        self.writeModule(symbol.culture)
        self.writeInteger(symbol.offset, endianness: .little)
    }
}
extension ByteBuffer
{
    mutating
    func readArticle() -> Article?
    {
        if  let culture:Module = self.readModule(),
            let offset:UInt32 = self.readInteger(endianness: .little)
        {
            return .init(culture, offset: offset)
        }
        else
        {
            return nil
        }
    }
    mutating
    func writeArticle(_ article:Article)
    {
        self.writeModule(article.culture)
        self.writeInteger(article.offset, endianness: .little)
    }
}
extension ByteBuffer
{
    mutating
    func readDiacritic() -> Diacritic?
    {
        if  let culture:Module = self.readModule(),
            let host:Symbol = self.readSymbol()
        {
            return .init(host: host, culture: culture)
        }
        else
        {
            return nil
        }
    }
    mutating
    func writeDiacritic(_ diacritic:Diacritic)
    {
        self.writeModule(diacritic.culture)
        self.writeSymbol(diacritic.host)
    }
}
