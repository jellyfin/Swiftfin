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
    exit(0)
}

// Enumerate through the Translations directory to find all .strings files.
guard let enumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: nil) else {
    exit(1)
}
var files = [URL]()

// Collect all files with the .strings extension found in ./Translations.
for case let fileURL as URL in enumerator {
    if fileURL.pathExtension == "strings" {
        files.append(fileURL)
    }
}

// This regular expression pattern matches lines of the format:
// "Key" = "Value";
let regex = try! NSRegularExpression(pattern: "^\"([^\"]+)\"\\s*=\\s*\"([^\"]+)\";", options: [])

// Process each .strings file found.
for fileURL in files {
    // Attempt to read the file content.
    guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
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

        // Use regex to find and capture the key and value from the line.
        if let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
            let keyRange = Range(match.range(at: 1), in: line)!
            let valueRange = Range(match.range(at: 2), in: line)!
            let key = String(line[keyRange])
            let value = String(line[valueRange])
            entries[key] = value
        }
    }

    // Sort the keys alphabetically for consistent ordering.
    let sortedKeys = entries.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    // Build the new file content with a descriptive comment before each entry.
    var newContent = ""
    for key in sortedKeys {
        let value = entries[key]!
        // Insert a comment line above each localization entry describing the value.
        newContent += "// \(value)\n\"\(key)\" = \"\(value)\";\n\n"
    }

    // Write the updated, sorted, and commented localizations back to the file.
    try? newContent.write(to: fileURL, atomically: true, encoding: .utf8)
}
