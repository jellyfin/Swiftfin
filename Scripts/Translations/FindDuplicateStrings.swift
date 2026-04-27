//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// Path to the English localization file.
let localizationFile = "./Translations/en.lproj/Localizable.strings"

// Directories to scan for L10n usage.
let directoriesToScan = ["./Shared", "./Swiftfin", "./Swiftfin tvOS"]

// File to exclude from scanning for replacements.
// - Only used for --dry and --replace
let excludedFile = "./Shared/Strings/Strings.swift"

// --dry previews proposed changes.
// --replace applies proposed changes.
let isDryRun = CommandLine.arguments.contains("--dry")
let isReplace = CommandLine.arguments.contains("--replace")

guard !(isReplace && isDryRun) else {
    print("Cannot use --dry and --replace together.")
    exit(1)
}

// Matches lines like "key" = "value"; in Localizable.strings.
let localizationRegex = #/^\"(?<key>[^\"]+)\"\s*=\s*\"(?<value>(?:[^\"\\]|\\.)*)\";\s*$/#

guard let localizationContent = try? String(contentsOfFile: localizationFile, encoding: .utf16) else {
    print("Unable to read localization file at \(localizationFile)")
    exit(1)
}

var entries = [String: String]()
for line in localizationContent.components(separatedBy: .newlines) {
    if let match = line.firstMatch(of: localizationRegex) {
        entries[String(match.output.key)] = String(match.output.value)
    }
}

let groupedByValue = Dictionary(grouping: entries, by: \.value)
let duplicates = groupedByValue.filter { $0.value.count > 1 }

if duplicates.isEmpty {
    print("No duplicate localization strings found.")
    exit(0)
}

// Rank a duplicate group so the shortest key is first.
// - The key .auto gets picked over .bitrateAuto
func rankKeys(_ pairs: [Dictionary<String, String>.Element]) -> [String] {
    pairs
        .map(\.key)
        .sorted {
            $0.count == $1.count ? $0 < $1 : $0.count < $1.count
        }
}

// Map each duplicate key the shortest matching alternative.
var keyMapping = [String: String]()

for (_, group) in duplicates {
    let ranked = rankKeys(group)
    let canonical = ranked[0]
    for duplicate in ranked.dropFirst() {
        keyMapping[duplicate] = canonical
    }
}

// MARK: - Report

let sortedGroups = duplicates.sorted { $0.key < $1.key }

print("Found \(duplicates.count) duplicate value(s) across \(keyMapping.count + duplicates.count) key(s):\n")

for (value, group) in sortedGroups {
    let ranked = rankKeys(group)
    let canonical = ranked[0]

    print("  \"\(value)\"")
    print("    - L10n.\(canonical) (keep)")

    for duplicate in ranked.dropFirst() {
        print("    - L10n.\(duplicate) → L10n.\(canonical)")
    }
}

// Output an error if duplicates were found.
// - Instructions change based on if this was a dry run.
if !isReplace {

    if isDryRun {
        print("\nDry run — no changes written. Run with --replace to apply them.")
    } else {
        print(
            "\nRun 'swift Scripts/Translations/FindDuplicateStrings.swift --dry' to preview changes, or --replace to apply them."
        )
    }

    exit(1)
}

// MARK: - Apply replacements

// Rewrite `L10n.<old>` → `L10n.<new>` in a Swift file.
func rewriteL10nReferences(in filePath: String) -> Int {
    guard var content = try? String(contentsOfFile: filePath, encoding: .utf8) else { return 0 }

    let before = content

    for (oldKey, newKey) in keyMapping {

        // The `\b` word boundary prevents `L10n.foo` from getting confused with `L10n.fooBar` when `foo` is remapped.
        let pattern = #"L10n\.\#(oldKey)\b"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }

        let ns = content as NSString
        let range = NSRange(location: 0, length: ns.length)

        content = regex.stringByReplacingMatches(
            in: content,
            range: range,
            withTemplate: "L10n.\(newKey)"
        )
    }

    guard content != before else { return 0 }

    do {
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    } catch {
        print("Error: failed to write \(filePath): \(error)")
        exit(2)
    }
    return 1
}

// Scan a directory recursively for Swift files.
var rewrittenFiles = 0

func scanDirectory(_ path: String) {
    let fileManager = FileManager.default

    guard let enumerator = fileManager.enumerator(atPath: path) else { return }

    for case let file as String in enumerator {
        let filePath = "\(path)/\(file)"

        // Skip the SwiftGen output since it gets regenerated at build.
        if filePath == excludedFile { continue }

        if file.hasSuffix(".swift") {
            rewrittenFiles += rewriteL10nReferences(in: filePath)
        }
    }
}

for directory in directoriesToScan {
    scanDirectory(directory)
}

for oldKey in keyMapping.keys {
    entries.removeValue(forKey: oldKey)
}

let sortedKeys = entries.keys.sorted {
    $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
}

let body = sortedKeys
    .map { "/// \(entries[$0]!)\n\"\($0)\" = \"\(entries[$0]!)\";" }
    .joined(separator: "\n\n")

do {
    try body.write(toFile: localizationFile, atomically: true, encoding: .utf16)
} catch {
    print("Error: failed to write \(localizationFile): \(error)")
    exit(2)
}

print("\nMerged \(keyMapping.count) duplicate key(s) across \(rewrittenFiles) file(s).")
print("Removed \(keyMapping.count) key(s) from \(localizationFile).")
print("\nRun 'swiftgen config run' to regenerate \(excludedFile).")

exit(0)
