<p align="center">
  <strong><em><code>biome</code></em></strong><br><small><code>0.3.2</code></small>
</p>

**`swift-biome`** is a versioned, multi-package Swift documentation compiler. 

Unlike DocC, Biome is not a site generator. Instead, it is meant to be the back-end component of a web service or a static site generator. Biome handles symbolgraph parsing, cross-linking, version control, organization, presentation, HTML rendering, and query routing.

Biome powers the [swiftinit.org ecosystem documentation](https://swiftinit.org/reference/swift)!

![screenshot](screenshots/screenshot@v0.3.2.png)

## Biome’s stack

Biome is built atop many of the same components as DocC. Its primary input source is the symbolgraph format generated by [`lib/SymbolGraphGen`](https://github.com/apple/swift/tree/main/lib/SymbolGraphGen). It also reads `Package.resolved`, and `Package.catalog`, which is generated by the [`swift-package-catalog`](https://github.com/kelvin13/swift-package-catalog) plugin.

Since v0.3.1, Biome compiles raw symbolgraphs ahead-of-time into the `ss` file format, which is a more performant, compact, and compression algorithm-friendly symbolgraph representation. 

Biome includes a tool, `swift-symbolgraphc`, which can be used to convert raw symbolgraphs into `ss` files.

The [`swift-biome-resources`](https://github.com/swift-biome/swift-biome-resources) submodule holds pre-compiled `ss` files for recent versions of the standard library, and various sources and webpacks for its default frontend.

The [`ecosystem`](https://github.com/swift-biome/ecosystem) repository is not tracked by this repository, but it contains historical `ss` files, `Package.resolved` files, and `Package.catalog` files for select ecosystem packages.