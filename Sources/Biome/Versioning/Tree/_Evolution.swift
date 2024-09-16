// import Forest

// struct Evolution 
// {
//     enum Label 
//     {
//         case extant 
//         case extinct 
//     }
//     struct Row 
//     {
//         let distance:Int 
//         let version:Version
//         var label:Label 
//         var fork:Bool

//         init(distance:Int = 0, version:Version, label:Label, fork:Bool = false)
//         {
//             self.distance = distance
//             self.version = version
//             self.label = label
//             self.fork = fork
//         }
//     }

//     var rows:[Row]

//     init(atomic symbol:AtomicPosition<Symbol>, 
//         in tree:__shared Tree, 
//         history:__shared History<Symbol.Metadata?>)
//     {
//         self.rows = []

//         let founder:Branch = tree[symbol.branch]
//         self.scan(founder: founder, tree: tree,
//             keyframes: history[founder.symbols[contemporary: symbol.atom].metadata])
//         {
//             history[$0.symbols.divergences[symbol.atom]?.metadata?.head]
//         }
//         label:
//         {
//             _ in .extant
//         }
//     }
//     init(compound:Compound, context:IsotropicContext)
//     {
//         self.rows = []
//         // compounds don’t “exist”, so their founder branch is always 
//         // the root branch (usually the default branch).
//         guard let pinned:Tree.Pinned = context[compound.nationality]
//         else 
//         {
//             return
//         }
//         let founder:Branch = pinned.package.tree.root(of: pinned.version.branch)

//         if compound.host.nationality == compound.nationality 
//         {
//             let history:History<Symbol.Metadata?> = pinned.package.metadata.symbols
//             self.scan(founder: founder, tree: pinned.package.tree, 
//                 keyframes: history[founder.symbols[contemporary: compound.host].metadata])
//             {
//                 history[$0.symbols.divergences[compound.host]?.metadata?.head]
//             }
//             label:
//             {
//                 if $0.contains(feature: compound)
//                 {
//                     return .extant
//                 }
//                 else 
//                 {
//                     return .extinct 
//                 }
//             }
//         }
//         else 
//         {

//         }
//     }
    
//     private mutating 
//     func scan(founder branch:Branch, tree:Tree,
//         keyframes:Forest<History<Symbol.Metadata?>.Keyframe>.Tree,
//         alternate:(Branch) throws -> Forest<History<Symbol.Metadata?>.Keyframe>.Tree,
//         label:(Symbol.Metadata) throws -> Label) rethrows
//     {
//         var keyframes:Forest<History<Symbol.Metadata?>.Keyframe>.Tree.Iterator = keyframes.makeIterator()

//         guard var regime:History<Symbol.Metadata?>.Keyframe = keyframes.next()
//         else 
//         {
//             return 
//         }
//         for revision:Version.Revision in branch.revisions.indices.reversed() 
//         {
//             if  revision < regime.since 
//             {
//                 guard let predecessor:History<Symbol.Metadata?>.Keyframe = keyframes.next() 
//                 else 
//                 {
//                     return 
//                 }
//                 regime = predecessor
//             }
//             let inherit:Label = try label(regime.value!)
//             for branch:Version.Branch in branch.revisions[revision].alternates 
//             {
//                 try self.scan(alternate: tree[branch], tree: tree, 
//                     inherit: inherit, 
//                     view: alternate,
//                     label: label)
//             }
//             self.rows.append(.init(version: .init(branch.index, revision), label: inherit))
//         }
//     }
//     private mutating 
//     func scan(alternate branch:Branch, tree:Tree,
//         distance:Int = 1, 
//         inherit:Label, 
//         view:(Branch) throws -> Forest<History<Symbol.Metadata?>.Keyframe>.Tree, 
//         label:(Symbol.Metadata) throws -> Label) rethrows 
//     {
//         var keyframes:Forest<History<Symbol.Metadata?>.Keyframe>.Tree.Iterator = try view(branch).makeIterator()

//         var regime:History<Symbol.Metadata?>.Keyframe? = keyframes.next()
//         let start:Version.Revision = branch.revisions.startIndex
//         for revision:Version.Revision in branch.revisions.indices.reversed() 
//         {
//             if  let inauguration:Version.Revision = regime?.since,
//                     revision < inauguration
//             {
//                 regime = keyframes.next() 
//             }
//             let inherit:Label = try regime.map { try label($0.value!) } ?? inherit
//             for alternate:Version.Branch in branch.revisions[revision].alternates 
//             {
//                 try self.scan(alternate: tree[alternate], tree: tree, 
//                     distance: distance + 1,
//                     inherit: inherit, 
//                     view: view,
//                     label: label)
//             }
//             self.rows.append(.init(distance: distance, 
//                 version: .init(branch.index, revision), 
//                 label: inherit, 
//                 fork: revision == start))
//         }
//     }
// }