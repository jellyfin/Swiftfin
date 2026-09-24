//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// Run from the repository root, or pass explicit input and output paths for tests.
guard CommandLine.arguments.count == 1 || CommandLine.arguments.count == 3 else {
    print("Usage: swift Scripts/Translations/GenerateStrings.swift [input.strings output.swift]")
    exit(1)
}

let fileURL = URL(fileURLWithPath: CommandLine.arguments.count == 3
    ? CommandLine.arguments[1] : "Translations/en.lproj/Localizable.strings")
let outputURL = URL(fileURLWithPath: CommandLine.arguments.count == 3
    ? CommandLine.arguments[2] : "Shared/Strings/Strings.swift")

// This regular expression pattern matches lines of the format:
// "Key" = "Value";
let regex = #/^"(?<key>(?:\\.|[^"\\])+)"\s*=\s*"(?<value>(?:\\.|[^"\\])*)";\s*$/#

// Attempt to read the file content.
guard let data = try? Data(contentsOf: fileURL) else {
    print("Unable to read file: \(fileURL.path)")
    exit(1)
}

let encoding: String.Encoding = data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) ? .utf16 : .utf8
guard let content = String(data: data, encoding: encoding) else {
    print("Unable to decode file: \(fileURL.path). Expected UTF-8 or UTF-16 with a byte order mark.")
    exit(1)
}

struct Entry {
    let value: String
    let comment: String?
    let line: Int
}

func fail(_ message: String, line: Int) -> Never {
    print("Error: \(fileURL.path):\(line): \(message)")
    exit(1)
}

var entries: [String: Entry] = [:]
var pendingComment: (text: String, line: Int)?
var pendingNotes: [(text: String, line: Int)] = []

// Associate generated documentation and ordinary // notes with the following entry.
for (index, rawLine) in content.components(separatedBy: .newlines).enumerated() {
    let lineNumber = index + 1
    let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
    if line.isEmpty {
        continue
    }

    if line.hasPrefix("///") {
        guard pendingComment == nil else {
            fail("Expected an entry after the preceding documentation comment.", line: lineNumber)
        }
        // Remove only the formatting space, preserving whitespace in the value.
        var text = String(line.dropFirst(3))
        if text.hasPrefix(" ") {
            text.removeFirst()
        }
        pendingComment = (text, lineNumber)
        continue
    }
    if line.hasPrefix("//") {
        let text = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        if !text.isEmpty {
            pendingNotes.append((text, lineNumber))
        }
        continue
    }

    guard let match = line.firstMatch(of: regex) else {
        fail("Invalid line format: \(line)", line: lineNumber)
    }
    let key = String(match.output.key)
    let value = String(match.output.value)
    guard entries[key] == nil else {
        fail("Duplicate key: \(key)", line: lineNumber)
    }

    var comment: String?
    if let pending = pendingComment {
        // Match the complete, escaped value first: either side may contain " - ".
        let prefix = value + " - "
        if pending.text.hasPrefix(prefix) {
            let suffix = String(pending.text.dropFirst(prefix.count))
            guard !suffix.trimmingCharacters(in: .whitespaces).isEmpty else {
                fail("Expected a comment after ' - '.", line: pending.line)
            }
            comment = suffix
        } else if pending.text.trimmingCharacters(in: .whitespaces) != value.trimmingCharacters(in: .whitespaces) {
            fail(
                "Expected '/// <English value>' or '/// <English value> - <comment>'; the value must match the following entry.",
                line: pending.line
            )
        }
    }
    // Fold multiple notes into the single generated documentation line in source order.
    var notes = pendingNotes
    if let comment, let pending = pendingComment {
        notes.append((comment, pending.line))
    }
    let combinedComment = notes.sorted { $0.line < $1.line }.map(\.text).joined(separator: " - ")
    entries[key] = Entry(value: value, comment: combinedComment.isEmpty ? nil : combinedComment, line: lineNumber)
    pendingComment = nil
    pendingNotes.removeAll()
}

if let pending = pendingComment {
    fail("Documentation comment has no following entry.", line: pending.line)
}

if let pending = pendingNotes.first {
    fail("Comment has no following entry.", line: pending.line)
}

// Sort the keys alphabetically for consistent ordering.
let sortedKeys = entries.keys.sorted {
    let left = $0.lowercased()
    let right = $1.lowercased()
    return left == right ? $0 < $1 : left < right
}

let newContent = sortedKeys.map { key in
    let entry = entries[key]!
    let suffix = entry.comment.map { " - \($0)" } ?? ""
    return "/// \(entry.value)\(suffix)\n\"\(key)\" = \"\(entry.value)\";"
}.joined(separator: "\n\n")

// Validate and render both outputs before writing either file.
let generatedContent = generateSwift(keys: sortedKeys, entries: entries)
do {
    if newContent != content {
        try newContent.write(to: fileURL, atomically: true, encoding: encoding)
    }
    // Keep timestamps stable to avoid recompilation when nothing changed.
    if (try? String(contentsOf: outputURL, encoding: .utf8)) != generatedContent {
        try generatedContent.write(to: outputURL, atomically: true, encoding: .utf8)
    }
} catch {
    print("Error: Failed to write generated strings: \(error)")
    exit(1)
}

// Decode .strings escapes using Foundation rather than treating them as Swift escapes.
func decodedValue(_ raw: String, line: Int) -> String {
    let source = "\"value\" = \"\(raw)\";"
    guard let dictionary = try? PropertyListSerialization.propertyList(
        from: Data(source.utf8), options: [], format: nil
    ) as? [String: String], let value = dictionary["value"] else {
        fail("Invalid escaped string value.", line: line)
    }
    return value
}

func generateSwift(keys: [String], entries: [String: Entry]) -> String {
    let keywords = Set("""
    associatedtype borrowing break case catch class consuming continue convenience copy default defer deinit didSet do
    dynamic else enum extension fallthrough false fileprivate final for func get guard if import indirect infix init inout
    internal in is isolated lazy left let macro mutating nil none nonisolated nonmutating open operator optional override
    package postfix precedencegroup prefix private protocol public repeat required rethrows return right self Self set
    some static struct subscript super switch throw throws true try typealias unowned var weak where while willSet
    """.split(whereSeparator: \.isWhitespace).map(String.init))
    var lines = [
        "// swiftlint:disable all",
        "// Generated by Scripts/Translations/GenerateStrings.swift. Do not edit.",
        "",
        "import Foundation",
        "",
        "internal enum L10n {"
    ]
    for key in keys {
        let entry = entries[key]!
        guard key.wholeMatch(of: #/[A-Za-z_][A-Za-z0-9_]*/#) != nil, key != "_", key != "tr" else {
            fail("Key '\(key)' must be a flat Swift identifier other than '_' or 'tr'.", line: entry.line)
        }
        let value = decodedValue(entry.value, line: entry.line)
        let types = argumentTypes(value, line: entry.line)
        let name = keywords.contains(key) ? "`\(key)`" : key
        let comment = entry.comment.map { " - \($0)" } ?? ""
        lines.append("  /// \(entry.value)\(comment)")
        let lookup = "L10n.tr(\"Localizable\", \(String(reflecting: key))"
        let fallback = "fallback: \(String(reflecting: value)))"
        if types.isEmpty {
            lines.append("  internal static let \(name) = \(lookup), \(fallback)")
        } else {
            let parameters = types.enumerated().map { "_ p\($0.offset + 1): \($0.element)" }.joined(separator: ", ")
            let arguments = types.enumerated().map {
                $0.element == "Any" ? "String(describing: p\($0.offset + 1))" : "p\($0.offset + 1)"
            }.joined(separator: ", ")
            lines.append("  internal static func \(name)(\(parameters)) -> String {")
            lines.append("    return \(lookup), \(arguments), \(fallback)")
            lines.append("  }")
        }
    }
    lines.append(contentsOf: [
        "}",
        "",
        "extension L10n {",
        "  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {",
        "    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)",
        "    return String(format: format, locale: Locale.current, arguments: args)",
        "  }",
        "}",
        "",
        "private final class BundleToken {",
        "  static let bundle: Bundle = {",
        "    #if SWIFT_PACKAGE",
        "    return Bundle.module",
        "    #else",
        "    return Bundle(for: BundleToken.self)",
        "    #endif",
        "  }()",
        "}",
        ""
    ])
    return lines.joined(separator: "\n")
}

// Parse printf arguments, including positional/repeated arguments and dynamic width/precision.
// Reject unsupported or inconsistent formats rather than generating an unsafe variadic call.
func argumentTypes(_ value: String, line: Int) -> [String] {
    let pattern = #/^%(?:(?<position>[0-9]+)\$)?[-+ #0']*(?<width>[0-9]+|\*(?:[0-9]+\$)?)?(?:\.(?<precision>[0-9]*|\*(?:[0-9]+\$)?))?(?<length>hh|ll|[hlqLztj])?(?<conversion>[@diuoxXfFeEgGaAcCsSp])/#
    var remaining = value[...]
    var arguments: [Int: String] = [:]
    var nextPosition = 1
    var usesPositions: Bool?

    func add(_ type: String, position: Substring?) {
        let positional = position != nil
        if let usesPositions, usesPositions != positional {
            fail("Cannot mix positional and sequential format arguments.", line: line)
        }
        usesPositions = positional
        let index: Int
        if let position {
            guard let parsed = Int(position), parsed > 0, parsed <= 100 else {
                fail("Format argument position must be between 1 and 100.", line: line)
            }
            index = parsed
        } else {
            index = nextPosition
            nextPosition += 1
        }
        if let previous = arguments[index], previous != type {
            fail("Conflicting types for format argument \(index).", line: line)
        }
        arguments[index] = type
    }

    func addSize(_ size: Substring?) {
        guard let size, size.hasPrefix("*") else { return }
        add("Int", position: size.hasSuffix("$") ? size.dropFirst().dropLast() : nil)
    }

    while let percent = remaining.firstIndex(of: "%") {
        remaining = remaining[percent...]
        if remaining.hasPrefix("%%") {
            remaining = remaining.dropFirst(2)
            continue
        }
        guard let match = remaining.firstMatch(of: pattern) else {
            fail("Unsupported format near '\(remaining)'. Use '%%' for a literal percent sign.", line: line)
        }
        let length = String(match.output.length ?? "")
        let conversion = String(match.output.conversion)
        let type: String
        switch conversion {
        case "d", "i", "u", "o", "x", "X":
            guard ["", "h", "hh", "l", "ll", "q", "z", "t", "j"].contains(length) else {
                fail("Unsupported integer format length: \(length)", line: line)
            }
            let signed = conversion == "d" || conversion == "i"
            let wide = ["ll", "q", "j"].contains(length)
            type = signed ? (wide ? "Int64" : "Int") : (wide ? "UInt64" : "UInt")
        case "f", "F", "e", "E", "g", "G", "a", "A":
            guard length.isEmpty || length == "l" else {
                fail("Unsupported floating-point format length: \(length)", line: line)
            }
            type = "Double"
        default:
            guard length.isEmpty else {
                fail("Unsupported format length for %\(conversion): \(length)", line: line)
            }
            switch conversion {
            case "@": type = "Any"
            case "c": type = "CChar"
            case "C": type = "UniChar"
            case "s": type = "UnsafePointer<CChar>"
            case "S": type = "UnsafePointer<UniChar>"
            default: type = "UnsafeRawPointer"
            }
        }
        addSize(match.output.width)
        addSize(match.output.precision)
        add(type, position: match.output.position)
        remaining = remaining[match.range.upperBound...]
    }
    guard let maximum = arguments.keys.max() else { return [] }
    return (1 ... maximum).map { index in
        guard let type = arguments[index] else {
            fail("Missing format argument position \(index).", line: line)
        }
        return type
    }
}
