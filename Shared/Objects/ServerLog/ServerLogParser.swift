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

    private struct Draft {
        var timestamp: Date?
        var level: ServerLogEntry.Level?
        var source: String?
        var message: String

        func build(id: Int) -> ServerLogEntry {
            ServerLogEntry(
                id: id,
                timestamp: timestamp,
                level: level,
                source: source,
                message: message
            )
        }
    }

    static func parse(_ text: String) -> [ServerLogEntry] {
        var entries: [ServerLogEntry] = []
        var draft: Draft?

        func flush() {
            guard let draft else { return }
            entries.append(draft.build(id: entries.count))
        }

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {

            if let match = try? lineRegex.wholeMatch(in: line) {

                flush()

                draft = Draft(
                    timestamp: timestampFormatter.date(from: String(match.output.1)),
                    level: ServerLogEntry.Level(rawValue: String(match.output.2)),
                    source: String(match.output.3),
                    message: String(match.output.4)
                )

            } else if draft != nil {
                draft?.message += "\n" + String(line)
            } else if !line.isEmpty {
                entries.append(Draft(message: String(line)).build(id: entries.count))
            }
        }

        flush()

        return entries
    }
}
