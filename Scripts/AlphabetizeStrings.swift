//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

// Look for all Localizable.strings files in Translations directory
let rootURL = URL(fileURLWithPath: "./Translations")

// Exit early if the Translations directory does not exist.
guard FileManager.default.fileExists(atPath: rootURL.path) else {
    print("Error: Translations directory not found.")
    exit(1)
}

// Enumerate through the Translations directory to find all .strings files.
guard let enumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: nil) else {
    print("Error: Failed to enumerate Translations directory.")
    exit(1)
}

// All .strings files in Translations directory
var files = [URL]()

// Collect all files with the .strings extension found in ./Translations.
for case let fileURL as URL in enumerator {
    if fileURL.pathExtension == "strings" {
        files.append(fileURL)
    }
}

// This regular expression pattern matches lines of the format:
// "Key" = "Value";
let regex = #/^\"(?<key>[^\"]+)\"\s*=\s*\"(?<value>[^\"]+)\";/#

// Process each .strings file found.
for fileURL in files {
    // Attempt to read the file content.
    guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
        print("Skipping unreadable file: \(fileURL.path)")
        continue
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
            entries[key] = value
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
}
