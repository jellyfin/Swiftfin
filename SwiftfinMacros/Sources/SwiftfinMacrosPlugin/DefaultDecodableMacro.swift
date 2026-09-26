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

struct DefaultDecodableMacro: ExtensionMacro {

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let declaration = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@DefaultDecodable can only be applied to a struct")
        }

        var keys: [String] = []
        var assignments: [String] = []

        for member in declaration.memberBlock.members {
            if member.decl.is(IfConfigDeclSyntax.self) {
                throw MacroExpansionErrorMessage("@DefaultDecodable does not support conditional members")
            }
            if let codingKeys = member.decl.as(EnumDeclSyntax.self), codingKeys.name.text == "CodingKeys" {
                throw MacroExpansionErrorMessage("@DefaultDecodable generates CodingKeys; remove the custom declaration")
            }
            if let initializer = member.decl.as(InitializerDeclSyntax.self),
               initializer.signature.parameterClause.parameters.count == 1,
               initializer.signature.parameterClause.parameters.first?.firstName.text == "from"
            {
                throw MacroExpansionErrorMessage("@DefaultDecodable generates init(from:); remove the custom initializer")
            }
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) else { continue }

            for binding in variable.bindings {
                if let accessorBlock = binding.accessorBlock {
                    switch accessorBlock.accessors {
                    case .getter:
                        continue
                    case let .accessors(accessors):
                        if accessors.contains(where: { !["willSet", "didSet"].contains($0.accessorSpecifier.text) }) {
                            continue
                        }
                    }
                }

                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                      let propertyType = binding.typeAnnotation?.type
                else {
                    throw MacroExpansionErrorMessage("@DefaultDecodable requires an explicit type for each stored property")
                }
                guard variable.attributes.isEmpty,
                      !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.lazy) })
                else {
                    throw MacroExpansionErrorMessage("@DefaultDecodable does not support attributed or lazy stored properties")
                }

                let name = identifier.identifier.trimmedDescription
                let hasDefault = binding.initializer != nil
                if hasDefault, variable.bindingSpecifier.tokenKind == .keyword(.let) {
                    throw MacroExpansionErrorMessage("@DefaultDecodable requires var for defaulted property '\(name)'")
                }

                keys.append("case \(name)")
                let wrappedType = optionalWrappedType(propertyType)
                let decodedType = (wrappedType ?? propertyType).trimmedDescription
                if hasDefault {
                    assignments.append("""
                    if let value = try container.decodeIfPresent(\(decodedType).self, forKey: .\(name)) {
                        self.\(name) = value
                    }
                    """)
                } else {
                    let method = wrappedType == nil ? "decode" : "decodeIfPresent"
                    assignments.append("self.\(name) = try container.\(method)(\(decodedType).self, forKey: .\(name))")
                }
            }
        }

        let access = declaration.modifiers.first { ["public", "package"].contains($0.name.text) }
            .map { "\($0.name.text) " } ?? ""
        let keyConformance = keys.isEmpty ? "CodingKey" : "String, CodingKey"
        let container = keys.isEmpty
            ? "_ = try decoder.container(keyedBy: CodingKeys.self)"
            : "let container = try decoder.container(keyedBy: CodingKeys.self)"
        let statements = CodeBlockItemListSyntax(stringLiteral: assignments.joined(separator: "\n"))
        let extensionDeclaration: DeclSyntax = """
        extension \(type.trimmed) {
            private enum CodingKeys: \(raw: keyConformance) {
                \(raw: keys.joined(separator: "\n"))
            }

            \(raw: access)init(from decoder: any Decoder) throws {
                \(raw: container)
                \(statements)
            }
        }
        """
        return [extensionDeclaration.formatted().cast(ExtensionDeclSyntax.self)]
    }

    private static func optionalWrappedType(_ type: TypeSyntax) -> TypeSyntax? {
        if let optional = type.as(OptionalTypeSyntax.self) {
            return optional.wrappedType
        }
        if let optional = type.as(IdentifierTypeSyntax.self), optional.name.text == "Optional",
           let arguments = optional.genericArgumentClause?.arguments, arguments.count == 1
        {
            return arguments.first?.argument
        }
        if let optional = type.as(MemberTypeSyntax.self), optional.baseType.trimmedDescription == "Swift",
           optional.name.text == "Optional", let arguments = optional.genericArgumentClause?.arguments,
           arguments.count == 1
        {
            return arguments.first?.argument
        }
        return nil
    }
}
