//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

// Get the English localization file
var fileURL = URL(fileURLWithPath: "./Translations/en.lproj/Localizable.strings")

// This regular expression pattern matches lines of the format:
// "Key" = "Value";
let regex = #/^\"(?<key>[^\"]+)\"\s*=\s*\"(?<value>[^\"]+)\";/#

// Attempt to read the file content.
guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
    print("Unable to read file: \(fileURL.path)")
    exit(1)
}

// Split file content by newlines to process line by line.
let lines = content.components(separatedBy: .newlines)
var entries = [String: String]()

// Extract key-value pairs from each valid line.
for line in lines {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

    // Ignore empty lines and lines starting with comments.
    if trimmed.isEmpty || trimmed.hasPrefix("//") { continue }

    if let match = line.firstMatch(of: regex) {
        let key = String(match.output.key)
        let value = String(match.output.value)

        // Add the key-value pair if the key is not already in the dictionary.
        if entries[key] == nil {
            entries[key] = value
        }
    } else {
        print("Error: Invalid line format in \(fileURL.path): \(line)")
        exit(1)
    }
}

// Sort the keys alphabetically for consistent ordering.
let sortedKeys = entries.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
let newContent = sortedKeys.map { "/// \(entries[$0]!)\n\"\($0)\" = \"\(entries[$0]!)\";" }.joined(separator: "\n\n")

// Write the updated, sorted, and commented localizations back to the file.
do {
    try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
} catch {
    print("Error: Failed to write to \(fileURL.path)")
    exit(1)
}
