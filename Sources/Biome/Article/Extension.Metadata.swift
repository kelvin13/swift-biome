import SymbolSource
import Markdown

extension Extension 
{
    enum PathDirective 
    {
        case explicit(Path)
        case implicit(Path)

        // replace spaces in the article name with hyphens
        static 
        func implicit(normalizing name:some StringProtocol) -> Self?
        {
            name.isEmpty ? nil : .implicit(.init(last: .init(name.map { $0 == " " ? "-" : $0 })))
        }
    }
    struct Metadata 
    {
        var path:PathDirective?
        var imports:Set<ModuleIdentifier> 
        var errors:[DirectiveArgumentText.ParseError]
        
        var noTitle:Bool
        
        init(directives:[BlockDirective])
        {
            self.path = nil
            self.errors = []
            self.imports = []
            
            self.noTitle = false
            
            let directives:[String: [BlockDirective]] = .init(grouping: directives, by: \.name)
            // @notitle 
            if  let anything:[BlockDirective] = directives["notitle"], !anything.isEmpty
            {
                self.noTitle = true
            }
            // @import(_:)
            if  let matches:[BlockDirective] = directives["import"]
            {
                for invocation:BlockDirective in matches 
                {
                    guard let imported:Substring = invocation.argumentText.segments.first?.trimmedText
                    else 
                    {
                        continue 
                    }
                    self.imports.insert(ModuleIdentifier.init(imported))
                }
            }
            // @path(_:)
            if  let matches:[BlockDirective] = directives["path"],
                let match:BlockDirective = matches.last, 
                let path:Path = .init(match.argumentText.segments
                    .map(\.trimmedText)
                    .joined()
                    .split(separator: "/")
                    .map(String.init(_:)))
            {
                self.path = .explicit(path)
            }
        }
    }
}
