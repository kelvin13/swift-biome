// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "swift-biome",
    products: 
    [
        .library(name: "Multiparts",            targets: ["Multiparts"]),
        .library(name: "Sediment",              targets: ["Sediment"]),
        .library(name: "URI",                   targets: ["URI"]),
        .library(name: "Versions",              targets: ["Versions"]),

        .library(name: "SymbolAvailability",    targets: ["SymbolAvailability"]),
        .library(name: "SymbolSource",          targets: ["SymbolSource"]),
        .library(name: "SymbolGraphs",          targets: ["SymbolGraphs"]),
        .library(name: "SymbolGraphCompiler",   targets: ["SymbolGraphCompiler"]),
        .library(name: "PackageResolution",     targets: ["PackageResolution"]),

        .library(name: "BiomeDatabase",         targets: ["BiomeDatabase"]),
        .library(name: "BiomeABI",              targets: ["BiomeABI"]),
        .library(name: "Biome",                 targets: ["Biome"]),

        .plugin(name: "SymbolGraphPlugin",      targets: ["SymbolGraphPlugin"]),

        .executable(name: "swift-biome-server", targets: ["swift-biome-server"]),
        .executable(name: "swift-symbolgraphc", targets: ["swift-symbolgraphc"]),

        //.executable(name: "biome-tests",        targets: ["BiomeTests"]),
    ],
    dependencies: 
    [
        .package(url: "https://github.com/kelvin13/swift-json", branch: "master"),
        .package(url: "https://github.com/kelvin13/swift-grammar", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/kelvin13/swift-hash", .upToNextMinor(from: "0.4.6")),
        .package(url: "https://github.com/kelvin13/swift-mongodb", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/kelvin13/swift-highlight", .upToNextMinor(from: "0.1.4")),
        .package(url: "https://github.com/kelvin13/swift-web-semantics", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/kelvin13/swift-dom", .upToNextMinor(from: "0.5.2")),
        
        .package(url: "https://github.com/apple/swift-markdown.git",
            revision: "swift-5.8-DEVELOPMENT-SNAPSHOT-2023-02-09-a"),
        .package(url: "https://github.com/apple/swift-syntax.git",
            revision: "swift-5.8-DEVELOPMENT-SNAPSHOT-2023-02-09-a"),
        .package(url: "https://github.com/apple/swift-package-manager.git",
            revision: "swift-5.8-DEVELOPMENT-SNAPSHOT-2023-02-09-a"),
        
        .package(url: "https://github.com/apple/swift-system.git", .upToNextMinor(from: "1.1.1")),

        // only used by the BiomeServer target
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMinor(from: "2.46.0")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .upToNextMinor(from: "2.23.0")),
        //  current swift-argument-parser is newer, but we are limited by swift-driver
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.0.1")),
        .package(url: "https://github.com/swift-server/swift-backtrace.git", .upToNextMinor(from: "1.3.3")),

    ],
    targets: 
    [
        .target(name: "Multiparts", 
            dependencies: 
            [
                .product(name: "Grammar",           package: "swift-grammar"),
            ]),
        
        .target(name: "PieCharts", 
            dependencies: 
            [
                .product(name: "SVG",               package: "swift-dom"),
            ]),
        
        .target(name: "Sediment"),
        
        .target(name: "URI", 
            dependencies: 
            [
                .product(name: "Grammar",           package: "swift-grammar"),
            ]),
        
        .target(name: "Versions", 
            dependencies: 
            [
                .product(name: "Grammar",           package: "swift-grammar"),
            ]),
        
        .target(name: "SymbolAvailability", 
            dependencies: 
            [
                .target(name: "Versions"),
            ]),
        
        .target(name: "SymbolSource", 
            dependencies: 
            [
                .product(name: "Grammar",           package: "swift-grammar"),
                .product(name: "Notebook",          package: "swift-highlight"),
            ]),
        
        .target(name: "SymbolGraphs", 
            dependencies: 
            [
                .target(name: "SymbolSource"),
                .target(name: "SymbolAvailability"),

                .product(name: "JSON",              package: "swift-json"),
            ],
            swiftSettings:
            [
                .unsafeFlags(["-Xfrontend", "-enable-experimental-move-only"]),
            ]),
        
        .target(name: "SymbolGraphCompiler", 
            dependencies: 
            [
                .target(name: "SymbolGraphs"),
                .target(name: "SystemExtras"),
                .product(name: "JSON",              package: "swift-json"),
            ]),
        
        .executableTarget(name: "swift-symbolgraphc", 
            dependencies: 
            [
                .target(name: "SymbolGraphCompiler"),
                .product(name: "ArgumentParser",    package: "swift-argument-parser"),
            ]),
        
        .plugin(name: "SymbolGraphPlugin",
            capability: .command(intent: .custom(verb: "symbolgraph", 
                description: "compile symbolgraphs and documentation")),
            dependencies: 
            [
                .target(name: "swift-symbolgraphc")
            ]),
        
        // only used by the SymbolGraphCompiler target
        .target(name: "SystemExtras", 
            dependencies: 
            [
                .product(name: "SystemPackage", package: "swift-system"),
            ]),
        
        .target(name: "PackageResolution", 
            dependencies: 
            [
                .target(name: "SymbolSource"),

                .product(name: "JSON", package: "swift-json"),
            ]),
        
        .target(name: "BiomeABI"),
        
        .target(name: "BiomeDatabase",
            dependencies: 
            [
                .target(name: "BiomeABI"),
                .product(name: "MongoDB", package: "swift-mongodb"),
                
                .product(name: "WebSemantics", package: "swift-web-semantics"),
            ]),
        
        .target(name: "Biome",
            dependencies: 
            [
                .target(name: "BiomeDatabase"),
                .target(name: "Multiparts"),
                .target(name: "PieCharts"),
                .target(name: "PackageResolution"),
                .target(name: "Sediment"),
                .target(name: "SymbolGraphs"),
                .target(name: "URI"),

                .product(name: "HTML",              package: "swift-dom"),
                .product(name: "RSS",               package: "swift-dom"),
                .product(name: "JSON",              package: "swift-json"),
                .product(name: "Notebook",          package: "swift-highlight"),
                //.product(name: "IDEUtils",          package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax",       package: "swift-syntax"),
                .product(name: "IDEUtils",          package: "swift-syntax"),
                .product(name: "Markdown",          package: "swift-markdown"),
            ], 
            swiftSettings:
            [
                .unsafeFlags(["-Xfrontend", "-enable-experimental-move-only"]),
            ]),
        
        .executableTarget(name: "swift-biome-server", 
            dependencies: 
            [
                .target(name: "Biome"),
                .target(name: "SystemExtras"),
                
                .product(name: "NIOCore",           package: "swift-nio"),
                .product(name: "NIOHTTP1",          package: "swift-nio"),
                .product(name: "NIOSSL",            package: "swift-nio-ssl"),

                .product(name: "Backtrace",         package: "swift-backtrace"),
                .product(name: "ArgumentParser",    package: "swift-argument-parser"),
            ], 
            swiftSettings:
            [
                .unsafeFlags(["-Xfrontend", "-enable-experimental-move-only"]),
            ]),

        .executableTarget(name: "SedimentTests",
            dependencies:
            [
                .target(name: "Sediment"),
                .product(name: "Testing", package: "swift-hash"),
            ], 
            path: "Tests/Sediment"),
        

        .executableTarget(name: "SymbolGraphExtractTests",
            dependencies:
            [
                .product(name: "SwiftPM", package: "swift-package-manager"),
            ], 
            path: "Tests/SymbolGraphExtract"),
        
        // .executableTarget(name: "BiomeTests", 
        //     dependencies: 
        //     [
        //         .target(name: "Biome"),
        //     ], 
        //     path: "Tests/BiomeTests"),

        .target(name: "ZooInheritedTypePrecedence",
            dependencies:
            [
            ], 
            path: "Zoo/InheritedTypePrecedence"),

        .target(name: "ZooInheritedTypes",
            dependencies:
            [
            ], 
            path: "Zoo/InheritedTypes"),

        .target(name: "ZooOverloadedTypealiases",
            dependencies:
            [
            ], 
            path: "Zoo/OverloadedTypealiases"),
    ]
)
