//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// Path to the English localization file
let localizationFile = "./Translations/en.lproj/Localizable.strings"

// Directories to scan for Swift files
let directoriesToScan = ["./Shared", "./Swiftfin", "./Swiftfin tvOS"]

// File to exclude from scanning
let excludedFile = "./Shared/Strings/Strings.swift"

// Regular expressions to match localization entries and usage in Swift files
// Matches lines like "Key" = "Value";
let localizationRegex = #/^\"(?<key>[^\"]+)\"\s*=\s*\"(?<value>[^\"]+)\";$/#

// Matches usage like L10n.key in Swift files
let usageRegex = #/L10n\.(?<key>[a-zA-Z0-9_]+)/#

// Attempt to load the localization file's content
guard let localizationContent = try? String(contentsOfFile: localizationFile, encoding: .utf16) else {
    print("Unable to read localization file at \(localizationFile)")
    exit(1)
}

// Split the file into lines and initialize a dictionary for localization entries
let localizationLines = localizationContent.components(separatedBy: .newlines)
var localizationEntries = [String: String]()

// Parse each line to extract key-value pairs
for line in localizationLines {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

    // Skip empty lines or comments
    if trimmed.isEmpty || trimmed.hasPrefix("//") { continue }

    // Match valid localization entries and add them to the dictionary
    if let match = line.firstMatch(of: localizationRegex) {
        let key = String(match.output.key)
        let value = String(match.output.value)
        localizationEntries[key] = value
    }
}

// Set to store all keys found in the codebase
var usedKeys = Set<String>()

// Function to scan a directory recursively for Swift files
func scanDirectory(_ path: String) {
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(atPath: path) else { return }

    for case let file as String in enumerator {
        let filePath = "\(path)/\(file)"

        // Skip the excluded file
        if filePath == excludedFile { continue }

        // Process only Swift files
        if file.hasSuffix(".swift") {
            if let fileContent = try? String(contentsOfFile: filePath, encoding: .utf8) {
                for line in fileContent.components(separatedBy: .newlines) {
                    // Find all matches for L10n.key in each line
                    let matches = line.matches(of: usageRegex)
                    for match in matches {
                        let key = String(match.output.key)
                        usedKeys.insert(key)
                    }
                }
            }
        }
    }
}

// Scan all specified directories
for directory in directoriesToScan {
    scanDirectory(directory)
}

// MARK: - Remove Unused Keys

// Identify keys in the localization file that are not used in the codebase
let unusedKeys = localizationEntries.keys.filter { !usedKeys.contains($0) }

// Remove unused keys from the dictionary
unusedKeys.forEach { localizationEntries.removeValue(forKey: $0) }

// MARK: - Write Updated Localizable.strings

// Sort keys alphabetically for consistent formatting
let sortedKeys = localizationEntries.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

// Reconstruct the localization file with sorted and updated entries
let updatedContent = sortedKeys.map { "/// \(localizationEntries[$0]!)\n\"\($0)\" = \"\(localizationEntries[$0]!)\";" }
    .joined(separator: "\n\n")

// Attempt to write the updated content back to the localization file
do {
    try updatedContent.write(toFile: localizationFile, atomically: true, encoding: .utf16)
    print("Localization file updated. Removed \(unusedKeys.count) unused keys.")
} catch {
    print("Error: Failed to write updated localization file.")
    exit(1)
}
