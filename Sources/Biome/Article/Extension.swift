import Markdown
import DOM
import HTML

struct Extension:Sendable 
{
    enum Node 
    {
        case section(Heading, [Self])
        case block(any BlockMarkup)
        case aside(Aside, [any BlockMarkup])
    }
    
    private(set)
    var metadata:Metadata
    
    let headline:Headline
    let nodes:[Node]
    var sections:Sections
    
    var snippet:String 
    {
        self.summary?.plainText ?? ""
    }
    private 
    var summary:Paragraph? 
    {
        if case .block(let paragraph as Paragraph)? = self.nodes.first
        {
            return paragraph
        }
        else 
        {
            return nil
        }
    }
    
    init(markdown source:String, name:String = "")
    {
        self.init(root: .init(parsing: source, 
            options: [ .parseBlockDirectives, .parseSymbolLinks ]))
        // if there is no explicit `@path(_:)` directive, use the filename
        if case nil = self.metadata.path
        {
            self.metadata.path = .implicit(normalizing: name)
        }
    }
    private  
    init(root:Markdown.Document)
    {
        // `level` may skip levels
        typealias StackFrame = (heading:Headline, nodes:[Node])
        
        // partition the top level blocks by heading, and whether they are 
        // a block directive 
        var directives:[BlockDirective] = []
        var blocks:LazyMapSequence<MarkupChildren, BlockMarkup>.Iterator = 
            root.blockChildren.makeIterator()
        
        while let block:any BlockMarkup = blocks.next()
        {
            guard let directive:BlockDirective = block as? BlockDirective
            else 
            {
                var stack:(base:[StackFrame], top:StackFrame) 
                stack.top.nodes = []
                stack.base      = []
                var next:(any BlockMarkup)?
                if let heading:Heading = block as? Heading, heading.level <= 1
                {
                    stack.top.heading = .explicit(heading)
                    next = blocks.next() 
                }
                else 
                {
                    stack.top.heading = .implicit
                    next = block 
                }
                
                while let current:any BlockMarkup = next 
                {
                    next = blocks.next()
                    
                    guard let heading:Heading = current as? Heading 
                    else 
                    {
                        stack.top.nodes.append(.block(current))
                        continue 
                    }
                    // for example, an `h3` will own everything until the next `h3`.
                    while case .explicit(let authority) = stack.top.heading,
                            heading.level <= authority.level, 
                        // it’s possible for this to return nil, if the article had 
                        // an explicit title, and there is another `h1` somewhere inside 
                        // it. in this case, the root will behave like an ‘h0’ and 
                        // the `h1`s will become children.
                        var top:StackFrame = stack.base.popLast()
                    {
                        top.nodes.append(.section(authority, stack.top.nodes))
                        stack.top = top
                    }
                    // push the new heading onto the stack, which makes it the 
                    // current authority. the level of the new heading is not necessarily 
                    // the level of the previous authority incremented by 1.
                    // it can skip levels, and it can also have the same level, 
                    // if the document contains multiple `h1`s.
                    stack.base.append(stack.top)
                    stack.top.heading   = .explicit(heading)
                    stack.top.nodes     = []
                }
                // conclude the survey by pretending the document ends with 
                // an imaginary `h0` footer.
                while case .explicit(let authority) = stack.top.heading,
                    var top:StackFrame = stack.base.popLast()
                {
                    top.nodes.append(.section(authority, stack.top.nodes))
                    stack.top = top
                }
                // `case implicit` can only appear in the first element of the stack 
                // base, so `stack.base` is guaranteed to be empty at this point
                assert(stack.base.isEmpty)
                
                self.init(directives: directives, 
                    headline: stack.top.heading, nodes: stack.top.nodes)
                return
            }
            directives.append(directive)
        }
        self.init(directives: directives, headline: .implicit, nodes: [])
    }
    private 
    init(directives:[BlockDirective], headline:Headline, nodes:[Node])
    {
        self.metadata = .init(directives: directives)
        self.headline = headline
        self.sections = .init()
        self.nodes = self.sections.recognize(nodes: nodes)
    }
    
    var binding:String?
    {
        guard case .explicit(let headline) = self.headline 
        else 
        {
            return nil 
        }
        var spans:LazyMapSequence<MarkupChildren, InlineMarkup>.Iterator = 
            headline.inlineChildren.makeIterator()
        if  let owner:any InlineMarkup  = spans.next(), 
            case nil                    = spans.next(), 
            let owner:SymbolLink    = owner as? SymbolLink,
            let owner:String        = owner.destination, !owner.isEmpty
        {
            return owner
        }
        else 
        {
            return nil
        }
    }

    func rendered() -> (DOM.Flattened<String>, DOM.Flattened<String>)
    {
        var renderer:Renderer = .init(rank: self.headline.rank)
        // note: we *never* render the top-level heading. this will either be 
        // auto-generated (for owned symbols), or stored as plain text by the 
        // caller of this function.
        let first:HTML.Element<String>?, 
            remaining:ArraySlice<Node>
        if let paragraph:Paragraph = self.summary
        {
            first = .p(renderer.render(span: paragraph))
            remaining = self.nodes.dropFirst()
        }
        else 
        {
            first = nil 
            remaining = self.nodes[...]
        }
        
        renderer.append(sections: self.sections)
        if case .implicit = self.headline 
        {
            renderer.append(nodes: remaining, under: "Overview", classes: "discussion")
        }
        else 
        {
            renderer.append(nodes: remaining)
        }
        let discussion:DOM.Flattened<String> = .init(freezing: renderer.elements)
        let summary:DOM.Flattened<String>
        if let first:HTML.Element<String> = first 
        {
            summary = .init(freezing: first)
        }
        else 
        {
            summary = .init()
        }
        if !renderer.errors.isEmpty
        {
            print("warning: ignored \(renderer.errors.count) markdown rendering errors")
        }
        return (summary, discussion)
    }
}
