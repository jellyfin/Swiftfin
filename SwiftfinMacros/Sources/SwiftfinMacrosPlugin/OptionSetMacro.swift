//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct OptionSetMacro: MemberMacro, ExtensionMacro {

    private struct Definition {
        let rawType: TypeSyntax
        let cases: [EnumCaseElementSyntax]
        let access: String
    }

    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let definition = try definition(of: node, declaration: declaration)
        let access = definition.access
        let members: [DeclSyntax] = [
            "\(raw: access)typealias RawValue = \(definition.rawType.trimmed)",
            "\(raw: access)let rawValue: RawValue",
            """
            \(raw: access)init(rawValue: RawValue) {
                self.rawValue = rawValue
            }
            """,
        ]
        return members + definition.cases.map { option in
            """
            \(raw: access)static let \(option.name.trimmed): Self = Self(rawValue: 1 << Options.\(option.name.trimmed).rawValue)
            """
        }
    }

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // The member expansion reports invalid declarations; avoid duplicate diagnostics here.
        guard (try? definition(of: node, declaration: declaration)) != nil else { return [] }
        if declaration.inheritanceClause?.inheritedTypes.contains(where: {
            ["OptionSet", "Swift.OptionSet"].contains($0.type.trimmedDescription)
        }) == true {
            return []
        }
        return try [ExtensionDeclSyntax("extension \(type.trimmed): Swift.OptionSet {}")]
    }

    private static func definition(
        of node: AttributeSyntax,
        declaration: some DeclGroupSyntax
    ) throws -> Definition {
        guard let declaration = declaration.as(StructDeclSyntax.self), declaration.genericParameterClause == nil else {
            throw MacroExpansionErrorMessage("@OptionSet requires a nongeneric struct")
        }

        let arguments = node.attributeName.as(IdentifierTypeSyntax.self)?.genericArgumentClause?.arguments
            ?? node.attributeName.as(MemberTypeSyntax.self)?.genericArgumentClause?.arguments
        guard let arguments, arguments.count == 1, let rawType = arguments.first?.argument,
              let width = bitWidth(of: rawType)
        else {
            throw MacroExpansionErrorMessage("@OptionSet requires a standard integer raw type, such as @OptionSet<Int>")
        }

        guard let options = declaration.memberBlock.members.compactMap({ $0.decl.as(EnumDeclSyntax.self) })
            .first(where: { $0.name.text == "Options" }),
            options.inheritanceClause?.inheritedTypes.first.map({ ["Int", "Swift.Int"].contains($0.type.trimmedDescription) }) == true
        else {
            throw MacroExpansionErrorMessage("@OptionSet requires a nested Options enum with raw type Int")
        }

        var cases: [EnumCaseElementSyntax] = []
        var nextPosition = 0
        var positions: Set<Int> = []
        for member in options.memberBlock.members {
            guard let declaration = member.decl.as(EnumCaseDeclSyntax.self), declaration.attributes.isEmpty else {
                throw MacroExpansionErrorMessage("@OptionSet Options must contain only unconditional, unattributed cases")
            }
            for option in declaration.elements {
                guard option.parameterClause == nil else {
                    throw MacroExpansionErrorMessage("@OptionSet cases cannot have associated values")
                }
                let position: Int
                if let value = option.rawValue {
                    guard let literal = value.value.as(IntegerLiteralExprSyntax.self),
                          let parsed = integerValue(literal.literal.text)
                    else {
                        throw MacroExpansionErrorMessage("@OptionSet bit positions must be nonnegative integer literals")
                    }
                    position = parsed
                } else {
                    position = nextPosition
                }
                guard position < width else {
                    throw MacroExpansionErrorMessage("@OptionSet bit position \(position) must be less than \(width)")
                }
                guard positions.insert(position).inserted else {
                    throw MacroExpansionErrorMessage("@OptionSet bit position \(position) is used more than once")
                }
                nextPosition = position + 1
                cases.append(option)
            }
        }
        guard !cases.isEmpty else {
            throw MacroExpansionErrorMessage("@OptionSet requires at least one option")
        }

        let generatedNames = Set(["RawValue", "rawValue"] + cases.map(\.name.text))
        for member in declaration.memberBlock.members {
            if member.decl.is(IfConfigDeclSyntax.self) {
                throw MacroExpansionErrorMessage("@OptionSet does not support conditional members")
            }
            if let alias = member.decl.as(TypeAliasDeclSyntax.self), generatedNames.contains(alias.name.text) {
                throw MacroExpansionErrorMessage("@OptionSet generates '\(alias.name.text)'; remove the existing declaration")
            }
            if let variable = member.decl.as(VariableDeclSyntax.self) {
                for binding in variable.bindings {
                    if let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text, generatedNames.contains(name) {
                        throw MacroExpansionErrorMessage("@OptionSet generates '\(name)'; remove the existing declaration")
                    }
                }
            }
            if let initializer = member.decl.as(InitializerDeclSyntax.self),
               initializer.signature.parameterClause.parameters.count == 1,
               initializer.signature.parameterClause.parameters.first?.firstName.text == "rawValue"
            {
                throw MacroExpansionErrorMessage("@OptionSet generates init(rawValue:); remove the existing initializer")
            }
        }

        let access = declaration.modifiers.first { ["public", "package"].contains($0.name.text) }
            .map { "\($0.name.text) " } ?? ""
        return Definition(rawType: rawType, cases: cases, access: access)
    }

    private static func bitWidth(of type: TypeSyntax) -> Int? {
        let description = type.trimmedDescription
        let name = description.hasPrefix("Swift.") ? String(description.dropFirst(6)) : description
        switch name {
        case "Int8", "UInt8": return 8
        case "Int16", "UInt16": return 16
        case "Int32", "UInt32": return 32
        case "Int", "UInt", "Int64", "UInt64": return 64
        default: return nil
        }
    }

    private static func integerValue(_ text: String) -> Int? {
        let digits = text.filter { $0 != "_" }
        for (prefix, radix) in [("0b", 2), ("0o", 8), ("0x", 16)] where digits.hasPrefix(prefix) {
            return Int(digits.dropFirst(2), radix: radix)
        }
        return Int(digits)
    }
}
