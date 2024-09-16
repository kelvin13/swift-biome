import DOM
import HTML
import Markdown
import SymbolSource

extension Extension
{
    /* enum RenderingError:Error 
    {
        case emptyImageSource
        case emptyLinkDestination
        
        case unsupportedMarkdown(String)
        
        // TODO: rework these
        case unsupportedMagicKeywords([String]) 
        
        case emptyReturnsField
        case emptyParameterField(name:String?) 
        case emptyParameterList
        
        case multipleReturnsFields([Rendered<UnresolvedLink>.Element], [Rendered<UnresolvedLink>.Element])
        
        case invalidParameterListItem(Rendered<UnresolvedLink>.Element)
        case invalidParameterList(Rendered<UnresolvedLink>.Element)
        case multipleParameterLists(Rendered<UnresolvedLink>.Element, Rendered<UnresolvedLink>.Element)
        
        /* var description:String 
        {
            switch self 
            {
            case .empty(parameter: nil):
                return "comment 'parameters' is completely empty"
            case .empty(parameter: let name?):
                return "comment 'parameter \(name)' is completely empty"
            case .invalidListItem(let item):
                return 
                    """
                    comment 'parameters' contains invalid list item:
                    '''
                    \(item.rendered)
                    '''
                    """
            case .invalidList(let block):
                return 
                    """
                    comment 'parameters' must contain a list, encountered:
                    '''
                    \(block.rendered)
                    '''
                    """
            case .multipleLists(let blocks):
                return 
                    """
                    comment 'parameters' must contain exactly one list, encountered:
                    '''
                    \(blocks.map(\.rendered).joined(separator: "\n"))
                    '''
                    """
            }
        } */
    } */
    struct Renderer 
    {
        private 
        let rank:Int
        private(set)
        var errors:[Error], 
            elements:[HTML.Element<String>]
        
        init(rank:Int)
        {
            self.rank = rank
            self.errors = []
            self.elements = []
        }
        
        private mutating 
        func report(invalid markup:any Markup) 
        {
            print("invalid markup: \(markup.debugDescription())")
        }
        
        mutating 
        func append(sections:Sections)
        {
            if !sections.parameters.isEmpty 
            {
                var list:[HTML.Element<String>] = []
                    list.reserveCapacity(2 * sections.parameters.count)
                for (name, content):(String, [any BlockMarkup]) in sections.parameters 
                {
                    list.append(.dt(name))
                    list.append(.dd(self.render(blocks: content)))
                }
                self.append([.dl(list)], under: "Parameters", classes: "parameters")
                
            }
            self.append(nodes: sections.returns.map(Node.block(_:)), 
                under: "Returns", classes: "returns")
        }
        mutating 
        func append<Nodes>(nodes:Nodes, under heading:String, classes:String)
            where Nodes:Sequence, Nodes.Element == Node
        {
            var elements:[HTML.Element<String>] = []
            self.render(nodes: nodes, into: &elements)
            if !elements.isEmpty 
            {
                self.append(elements, under: heading, classes: classes)
            }
        }
        mutating 
        func append<Nodes>(nodes:Nodes)
            where Nodes:Sequence, Nodes.Element == Node
        {
            var elements:[HTML.Element<String>] = self.elements 
            self.elements = []
            self.render(nodes: nodes, into: &elements)
            self.elements = elements
        }
        private mutating 
        func append(_ elements:[HTML.Element<String>], under heading:String, classes:String)
        {
            self.elements.append(.section([.h2(heading)] + elements, 
                attributes: [.class(classes)]))
        }
        private mutating 
        func render<Nodes>(nodes:Nodes, into elements:inout [HTML.Element<String>])
            where Nodes:Sequence, Nodes.Element == Node
        {
            for node:Node in nodes 
            {
                switch node 
                {
                case .block(let block): 
                    // rank should not matter
                    elements.append(self.render(block: block))
                
                case .aside(let aside, let content):
                    elements.append(self.render(aside: aside, content: content))
                    
                case .section(let heading, let children):
                    elements.append(self.render(heading: heading))
                    self.render(nodes: children, into: &elements)
                }
            }
        }

        private mutating 
        func render(aside:Aside, content:[any BlockMarkup]) -> HTML.Element<String> 
        {
            .aside([.h3(aside.prose)] + self.render(blocks: content), 
                attributes: [.class(aside.class)])
        }
        private mutating 
        func render(blocks:some Sequence<any BlockMarkup>) -> [HTML.Element<String>] 
        {
            blocks.map 
            {
                self.render(block: $0)
            }
        }
        private mutating 
        func render(block:any BlockMarkup) -> HTML.Element<String> 
        {
            switch block 
            {
            case let aside as BlockQuote:
                let aside:Markdown.Aside = .init(aside)
                return self.render(aside: .init(aside.kind), content: aside.content)
            
            case is CustomBlock:
                return .div("(unsupported custom block)")
            case let block as HTMLBlock:
                return .init(escaped: block.rawHTML)
            
            case let directive as BlockDirective:
                return self.render(directive: directive)
            case let item as ListItem:
                return .li(self.render(blocks: item.blockChildren))
            case let list as OrderedList:
                return .ol(self.render(list: list))
            case let list as UnorderedList:
                return .ul(self.render(list: list))
            case let block as CodeBlock:
                return Self.highlight(block: block.code, 
                    as: block.language.map { $0.lowercased() == "swift" ? .swift : .text } ?? .swift)
            case let heading as Heading: 
                return self.render(heading: heading)
            case let paragraph as Paragraph:
                return .p(self.render(span: paragraph))
            case let table as Table:
                return self.render(table: table)
            case is ThematicBreak: 
                return .hr
            case let markup: 
                self.report(invalid: markup)
                return .div("(unsupported block markdown node '\(type(of: markup))')")
            }
        }

        private static
        func highlight(block code:String, as language:CodeBlockLanguage) -> HTML.Element<String> 
        {
            var fragments:[HTML.Element<String>] = [.highlight(escaped: "", .newlines)]
            switch language 
            {
            case .text: 
                var lines:[Substring] = code.split(separator: "\n", omittingEmptySubsequences: false)
                while case true? = lines.last?.isEmpty 
                {
                    lines.removeLast()
                }
                if let first:Substring = lines.first 
                {
                    fragments.append(.init(first))
                }
                for next:Substring in lines.dropFirst()
                {
                    fragments.append(.highlight(escaped: "\n", .newlines))
                    fragments.append(.init(next))
                }
            case .swift:
                for (text, color):(String, Highlight) in Self.highlight(code)
                {
                    fragments.append(.highlight(text, color))
                }
            }
            
            return .pre(.code(fragments, attributes: [.class(language.rawValue)]), 
                attributes: [.class("notebook")])
        }
        private static
        func highlight(inline code:String, as language:CodeBlockLanguage) -> HTML.Element<String> 
        {
            let attributes:[HTML.Element<String>.Attribute] = [.class(language.rawValue)]
            switch language 
            {
            case .text: 
                return .code(code, 
                    attributes: attributes)
            case .swift:
                return .code(Self.highlight(code).map { .highlight($0.text, $0.color) }, 
                    attributes: attributes)
            }
        }
        private 
        func highlight(inline link:Markdown.Link) -> HTML.Element<String>?
        {
            let spans:[any InlineMarkup] = .init(link.inlineChildren)
            guard   let span:any InlineMarkup = spans.first, spans.count == 1,
                    let span:InlineCode = span as? InlineCode 
            else 
            {
                return nil 
            }
            return Self.highlight(inline: span.code, as: .swift)
        }
        
        private mutating 
        func render(heading:Heading) -> HTML.Element<String>
        {
            switch heading.level + self.rank
            {
            case ...1:  return .h1(self.render(span: heading))
            case    2:  return .h2(self.render(span: heading))
            case    3:  return .h3(self.render(span: heading))
            case    4:  return .h4(self.render(span: heading))
            case    5:  return .h5(self.render(span: heading))
            default:    return .h6(self.render(span: heading))
            }
            /* return Element[.h2]
            {
                ("subsection-\(index)", as: HTML.ID.self)
            }
            content: 
            {
                Element[.span] 
                {
                    ("class", "subsection-anchor")
                } 
                content: 
                {
                    Element.link("\(index)", to: "#subsection-\(index)")
                }
                headings().joined() as FlattenSequence<[[Element]]>
            } */
        }
        private mutating 
        func render(directive:BlockDirective) -> HTML.Element<String> 
        {
            switch directive.name 
            {
            case let undefined:
                return .div("(unsupported block directive of type '\(undefined)')")
            }
        }
        private mutating 
        func render(list:some ListItemContainer) -> [HTML.Element<String>] 
        {
            list.listItems.map
            {
                .li(self.render(blocks: $0.blockChildren))
            }
        }
        private mutating 
        func render(row:some TableCellContainer) -> [HTML.Element<String>] 
        {
            row.cells.map
            {
                .td(self.render(span: $0))
            }
        }
        private mutating 
        func render(rows body:Table.Body) -> [HTML.Element<String>] 
        {
            body.rows.map
            {
                .tr(self.render(row: $0))
            }
        }
        private mutating 
        func render(table:Table) -> HTML.Element<String> 
        {
            .table(
                .thead(.tr(self.render(row: table.head))),
                .tbody(self.render(rows: table.body)))
        }
        
        private mutating 
        func render(image:Markdown.Image) -> HTML.Element<String>
        {
            var attributes:[HTML.Element<String>.Attribute] = []
            if let source:String = image.source, !source.isEmpty
            {
                attributes.append(.src(source))
            }
            else 
            {
                self.report(invalid: image)
            }
            if let title:String = image.title 
            {
                attributes.append(.alt(title))
            }
            return .figure(.img(attributes: attributes), .figcaption(self.render(span: image)))
        }

        private mutating 
        func render(link:Markdown.Link) -> HTML.Element<String>
        {
            guard let destination:String = link.destination, !destination.isEmpty
            else 
            {
                if  let code:HTML.Element<String> = self.highlight(inline: link)
                {
                    return code
                }
                else 
                {
                    self.report(invalid: link)
                    return .span(self.render(span: link))
                }
            }
            if destination.starts(with: "doc:")
            {
                return .init(anchor: destination)
            }
            // assume link is external. at some point 
            // we want to be smarter about nofollow/noopener
            let content:[HTML.Element<String>] = link.inlineChildren.map
            {
                self.render(inline: $0)
            }
            return .a(content, attributes:
            [
                .href(destination),
                .target("_blank"),
                .rel("nofollow"),
            ]) 
        }
        private mutating 
        func render(link:SymbolLink) -> HTML.Element<String>
        {
            if let string:String = link.destination
            {
                return .init(anchor: string)
            }
            else 
            {
                self.report(invalid: link)
                return .code("<empty symbol path>")
            }
        }
        
        // inline rendering 
        mutating 
        func render(span:some InlineContainer) -> [HTML.Element<String>]
        {
            span.inlineChildren.map
            {
                self.render(inline: $0)
            }
        }
        private mutating 
        func render(inline:any InlineMarkup) -> HTML.Element<String>
        {
            switch inline
            {
            case is LineBreak:
                return .br
            case is SoftBreak:
                return .init(escaped: " ")
            
            case let span as CustomInline: 
                return .init(span.text)
            case let text as Text:
                return .init(text.string)
            case let span as InlineHTML:
                return .init(span.rawHTML)
            case let span as InlineCode: 
                return .code(span.code)
            case let span as Emphasis:
                return .em(self.render(span: span))
            case let span as Strikethrough:
                return .s(self.render(span: span))
            case let span as Strong:
                return .strong(self.render(span: span))
            case let image as Markdown.Image: 
                return self.render(image: image)
            case let link as Markdown.Link: 
                return self.render(link: link)
            case let link as SymbolLink: 
                return self.render(link: link)
                
            case let unsupported: 
                self.report(invalid: unsupported)
                return .div("(unsupported inline markdown node '\(type(of: unsupported))')")
            }
        }
    } 
}
