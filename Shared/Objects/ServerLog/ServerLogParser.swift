//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Parses Jellyfin system server logs. Lines look like:
/// - `[2000-12-31 12:23:45.123 -06:00] [INF] [64] Source: message`.
/// - Non-matching lines attach to the previous entry (stack traces, exception bodies).
enum ServerLogParser {

    private static let lineRegex: Regex = /^\[([^\]]+)\] \[([A-Z]+)\] \[[^\]]+\] ([^:]+?): (.*)$/

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS XXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func parse(_ text: String) -> [ServerLogEntry] {
        var entries: [ServerLogEntry] = []

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {

            // Header lines always start with `[` so use this as a shortcut to skip early
            // - instead of going straight to regex which is much much heavier
            if line.first == "[", let match = try? lineRegex.wholeMatch(in: line) {

                // Begin a new entry when timestamps denote a new line
                entries.append(
                    ServerLogEntry(
                        id: entries.count,
                        timestamp: timestampFormatter.date(from: String(match.output.1)),
                        level: ServerLogEntry.Level(rawValue: String(match.output.2)),
                        source: String(match.output.3),
                        message: String(match.output.4)
                    )
                )

            } else if !entries.isEmpty {

                // Continue on the existing entry for multi-line logs.
                entries[entries.count - 1].message.append("\n")
                entries[entries.count - 1].message.append(contentsOf: line)

            } else if !line.isEmpty {

                // Handle empty orphan lines
                entries.append(
                    ServerLogEntry(
                        id: entries.count,
                        timestamp: nil,
                        level: nil,
                        source: nil,
                        message: String(line)
                    )
                )
            }
        }

        return entries
    }
}
