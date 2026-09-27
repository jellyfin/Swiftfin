//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

let localizationFile = "./Translations/en.lproj/Localizable.strings"
let directoriesToScan = ["./Shared", "./Swiftfin", "./Swiftfin tvOS"]
let excludedFile = "./Shared/Strings/Strings.swift"
let keyRegex = #/^\s*"(?<key>[^"\n]+)"\s*=/#
let usageRegex = #/L10n\.`?(?<key>[a-zA-Z0-9_]+)`?/#

guard let content = try? String(contentsOfFile: localizationFile, encoding: .utf16) else {
    print("Unable to read localization file at \(localizationFile)")
    exit(1)
}

var usedKeys = Set<String>()
for directory in directoriesToScan {
    guard let files = FileManager.default.enumerator(atPath: directory) else { continue }
    for case let file as String in files where file.hasSuffix(".swift") {
        let path = "\(directory)/\(file)"
        guard path != excludedFile,
              let source = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
        usedKeys.formUnion(source.matches(of: usageRegex).map { String($0.output.key) })
    }
}

var lines = content.components(separatedBy: "\n")
let unused = lines.enumerated().compactMap { index, line -> (index: Int, key: String)? in
    guard let match = line.firstMatch(of: keyRegex) else { return nil }
    let key = String(match.output.key)
    return usedKeys.contains(key) ? nil : (index, key)
}

guard !unused.isEmpty else {
    print("No unused localization strings found.")
    exit(0)
}

print("Found \(unused.count) unused localization string(s):\n")
for key in unused.map(\.key).sorted() {
    print("  - \(key)")
}

guard CommandLine.arguments.contains("--purge") else {
    print("\nRun 'swift Scripts/Translations/FindUnusedStrings.swift --purge' to remove them.")
    exit(1)
}

// Work backwards so deleting an entry does not shift the remaining indices.
for entry in unused.reversed() {
    var start = entry.index
    while start > 0, lines[start - 1].trimmingCharacters(in: .whitespaces).hasPrefix("//") {
        start -= 1
    }
    var end = entry.index + 1
    if end < lines.count, lines[end].isEmpty {
        end += 1
    }
    lines.removeSubrange(start ..< end)
}

do {
    try lines.joined(separator: "\n").write(toFile: localizationFile, atomically: true, encoding: .utf16)
    print("\nLocalization file updated. Removed \(unused.count) unused keys.")
} catch {
    print("\nError: Failed to write updated localization file.")
    exit(1)
}
