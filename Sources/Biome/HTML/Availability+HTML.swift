import HTML
import SymbolAvailability
import Versions

extension Availability:HTMLOptionalConvertible
{
    var html:HTML.Element<Never>?
    {
        var items:[HTML.Element<Never>] = []
        if  let item:HTML.Element<Never> = self.swift?.html
        {
            items.append(item)
        }
        if  let item:HTML.Element<Never> = self.general?.html
        {
            items.append(item)
        }
        return items.isEmpty ? nil : .ul(items, attributes: [.class("availability-list")])
    }
}
extension SwiftAvailability:HTMLOptionalConvertible
{
    var html:HTML.Element<Never>?
    {
        let adjective:String 
        let toolchain:HTML.Element<Never>
        if let version:SemanticVersion.Masked = self.obsoleted 
        {
            adjective = "Obsolete"
            toolchain = .span(version.description, attributes: [.class("version")])
        } 
        else if let version:SemanticVersion.Masked = self.deprecated 
        {
            adjective = "Deprecated"
            toolchain = .span(version.description, attributes: [.class("version")])
        }
        else if let version:SemanticVersion.Masked = self.introduced
        {
            adjective = "Available"
            toolchain = .span(version.description, attributes: [.class("version")])
        }
        else 
        {
            return nil
        }
        return .li(.strong(escaped: adjective), .init(escaped: " since Swift "), toolchain)
    }
}
extension UnversionedAvailability:HTMLOptionalConvertible
{
    var html:HTML.Element<Never>?
    {
        self.unavailable ? .li(.strong(escaped: "Unavailable")) : 
        self.deprecated  ? .li(.strong(escaped: "Deprecated"))  : nil
    }
}