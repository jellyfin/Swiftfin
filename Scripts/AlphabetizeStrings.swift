//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

let rootURL = URL(fileURLWithPath: "./Translations")
guard FileManager.default.fileExists(atPath: rootURL.path) else {
    exit(0)
}

guard let enumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: nil) else {
    exit(1)
}

var files = [URL]()
for case let fileURL as URL in enumerator {
    if fileURL.pathExtension == "strings" {
        files.append(fileURL)
    }
}

let regex = try! NSRegularExpression(pattern: "^\"([^\"]+)\"\\s*=\\s*\"([^\"]+)\";", options: [])

for fileURL in files {
    guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
        continue
    }

    let lines = content.components(separatedBy: .newlines)
    var entries = [String: String]()

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix("//") { continue }

        if let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
            let keyRange = Range(match.range(at: 1), in: line)!
            let valueRange = Range(match.range(at: 2), in: line)!
            let key = String(line[keyRange])
            let value = String(line[valueRange])
            entries[key] = value
        }
    }

    let sortedKeys = entries.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    var newContent = ""
    for key in sortedKeys {
        let value = entries[key]!
        newContent += "/// \(value)\n\"\(key)\" = \"\(value)\";\n\n"
    }

    try? newContent.write(to: fileURL, atomically: true, encoding: .utf8)
}
