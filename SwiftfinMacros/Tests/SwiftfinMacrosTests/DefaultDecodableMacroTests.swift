//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import SwiftfinMacrosPlugin
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct DefaultDecodableMacroTests {

    private let macroSpecs = ["DefaultDecodable": MacroSpec(type: DefaultDecodableMacro.self)]

    @Test
    func `expansion keeps initializers and skips non stored properties`() {
        assertMacroExpansion(
            """
            @DefaultDecodable
            struct Settings: Codable {
                var title: Bool = true
                let name: String
                var note: String?
                static let shared = Settings(name: "Default")
                var computed: Int { 1 }
            }
            """,
            expandedSource: """
            struct Settings: Codable {
                var title: Bool = true
                let name: String
                var note: String?
                static let shared = Settings(name: "Default")
                var computed: Int { 1 }
            }

            extension Settings {
                private enum CodingKeys: String, CodingKey {
                    case title
                    case name
                    case note
                }

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    if let value = try container.decodeIfPresent(Bool.self, forKey: .title) {
                        self.title = value
                    }
                    self.name = try container.decode(String.self, forKey: .name)
                    self.note = try container.decodeIfPresent(String.self, forKey: .note)
                }
            }
            """,
            macroSpecs: macroSpecs,
            failureHandler: recordFailure
        )
    }

    @Test
    func `diagnoses unsupported declarations`() {
        let cases: [(String, String)] = [
            ("class Settings: Codable {}", "@DefaultDecodable can only be applied to a struct"),
            (
                "struct Settings: Codable {\n    var title = true\n}",
                "@DefaultDecodable requires an explicit type for each stored property"
            ),
            (
                "struct Settings: Codable {\n    let title: Bool = true\n}",
                "@DefaultDecodable requires var for defaulted property 'title'"
            ),
            (
                "struct Settings: Codable {\n    lazy var title: Bool = true\n}",
                "@DefaultDecodable does not support attributed or lazy stored properties"
            ),
            (
                "struct Settings: Codable {\n    @Wrapper var title: Bool = true\n}",
                "@DefaultDecodable does not support attributed or lazy stored properties"
            ),
            (
                "struct Settings: Codable {\n    enum CodingKeys: CodingKey {}\n}",
                "@DefaultDecodable generates CodingKeys; remove the custom declaration"
            ),
            (
                "struct Settings: Codable {\n    init(from decoder: Decoder) throws {}\n}",
                "@DefaultDecodable generates init(from:); remove the custom initializer"
            ),
        ]
        for (declaration, message) in cases {
            assertMacroExpansion(
                "@DefaultDecodable\n\(declaration)",
                expandedSource: declaration,
                diagnostics: [DiagnosticSpec(message: message, line: 1, column: 1)],
                macroSpecs: macroSpecs,
                failureHandler: recordFailure
            )
        }
    }

    private func recordFailure(_ failure: TestFailureSpec) {
        Issue.record(
            Comment(rawValue: failure.message),
            sourceLocation: SourceLocation(
                fileID: failure.location.fileID,
                filePath: failure.location.filePath,
                line: failure.location.line,
                column: failure.location.column
            )
        )
    }
}
