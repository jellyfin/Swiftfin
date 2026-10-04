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

struct OptionSetMacroTests {

    private let macroSpecs = ["OptionSet": MacroSpec(type: OptionSetMacro.self, conformances: ["Swift.OptionSet"])]

    @Test
    func `expansion generates public members and conformance`() {
        assertMacroExpansion(
            """
            @OptionSet<UInt8>
            public struct Flags {
                private enum Options: Int {
                    case first = 1
                    case last = 7
                }
            }
            """,
            expandedSource: """
            public struct Flags {
                private enum Options: Int {
                    case first = 1
                    case last = 7
                }

                public typealias RawValue = UInt8

                public let rawValue: RawValue

                public init(rawValue: RawValue) {
                    self.rawValue = rawValue
                }

                public static let first: Self = Self(rawValue: 1 << Options.first.rawValue)

                public static let last: Self = Self(rawValue: 1 << Options.last.rawValue)
            }

            extension Flags: Swift.OptionSet {
            }
            """,
            macroSpecs: macroSpecs,
            failureHandler: recordFailure
        )
    }

    @Test
    func `invalid declarations emit a single diagnostic`() {
        let cases: [(String, String)] = [
            ("class Flags {}", "@OptionSet requires a nongeneric struct"),
            ("struct Flags<T> {}", "@OptionSet requires a nongeneric struct"),
            ("struct Flags {}", "@OptionSet requires a nested Options enum with raw type Int"),
            (
                "struct Flags {\n    enum Options: String {\n        case first\n    }\n}",
                "@OptionSet requires a nested Options enum with raw type Int"
            ),
            (
                "struct Flags {\n    enum Options: Int {}\n}",
                "@OptionSet requires at least one option"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first = -1\n    }\n}",
                "@OptionSet bit positions must be nonnegative integer literals"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first = 8\n    }\n}",
                "@OptionSet bit position 8 must be less than 8"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first = 7, next\n    }\n}",
                "@OptionSet bit position 8 must be less than 8"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first = 0, second = 0\n    }\n}",
                "@OptionSet bit position 0 is used more than once"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first(Int)\n    }\n}",
                "@OptionSet cases cannot have associated values"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first\n    }\n    let rawValue: UInt8\n}",
                "@OptionSet generates 'rawValue'; remove the existing declaration"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first\n    }\n    typealias RawValue = UInt8\n}",
                "@OptionSet generates 'RawValue'; remove the existing declaration"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first\n    }\n    static let first = 1\n}",
                "@OptionSet generates 'first'; remove the existing declaration"
            ),
            (
                "struct Flags {\n    enum Options: Int {\n        case first\n    }\n    init(rawValue: UInt8) {}\n}",
                "@OptionSet generates init(rawValue:); remove the existing initializer"
            ),
        ]
        for (declaration, message) in cases {
            assertMacroExpansion(
                "@OptionSet<UInt8>\n\(declaration)",
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
