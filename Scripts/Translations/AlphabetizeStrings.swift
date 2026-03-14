//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// Get the English localization file
let fileURL = URL(fileURLWithPath: "./Translations/en.lproj/Localizable.strings")

// This regular expression pattern matches lines of the format:
// "Key" = "Value";
let regex = #/^\"(?<key>[^\"]+)\"\s*=\s*\"(?<value>[^\"]+)\";/#

// Attempt to read the file content.
guard let content = try? String(contentsOf: fileURL, encoding: .utf16) else {
    print("Unable to read file: \(fileURL.path)")
    exit(1)
}

// Split file content by newlines to process line by line.
let strings = content.components(separatedBy: .newlines)
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty && !$0.hasPrefix("//") }

let entries = strings.reduce(into: [String: String]()) {
    if let match = $1.firstMatch(of: regex) {
        let key = String(match.output.key)
        let value = String(match.output.value)
        $0[key] = value
    } else {
        print("Error: Invalid line format in \(fileURL.path): \($1)")
        exit(1)
    }
}

// Sort the keys alphabetically for consistent ordering.
let sortedKeys = entries.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
let newContent = sortedKeys.map { "/// \(entries[$0]!)\n\"\($0)\" = \"\(entries[$0]!)\";" }.joined(separator: "\n\n")

// Write the updated, sorted, and commented localizations back to the file.
do {
    try newContent.write(to: fileURL, atomically: true, encoding: .utf16)

    if let derivedFileDirectory = ProcessInfo.processInfo.environment["DERIVED_FILE_DIR"] {
        try? "".write(toFile: derivedFileDirectory + "/alphabetizeStrings.txt", atomically: true, encoding: .utf16)
    }
} catch {
    print("Error: Failed to write to \(fileURL.path)")
    exit(1)
}
