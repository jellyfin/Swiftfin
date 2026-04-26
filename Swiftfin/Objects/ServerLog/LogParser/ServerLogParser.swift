//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Parse server system logs into timestamped `ServerLogEntry` records.
struct ServerLogParser: LogParser<ServerLogEntry> {

    let encoding: String.Encoding = .utf8
    let delimiter: String = "\n"

    private var pending: ServerLogEntry?
    private var nextID: Int = 0

    /// Format: `[2000-12-31 12:23:45.123 -06:00] [INF] [64] Source: message`
    /// Lines that don't match the header pattern attach to the previous entry
    private static let lineRegex: Regex = /^\[([^\]]+)\] \[([A-Z]+)\] \[[^\]]+\] ([^:]+?): (.*)$/

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS XXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Simple check for a starting bracket followed by a heavier full REGEX check.
    func isHeader(line: String) -> Bool {
        line.first == "[" && (try? Self.lineRegex.wholeMatch(in: line)) != nil
    }

    mutating func read(chunk line: String) -> [ServerLogEntry] {
        var output: [ServerLogEntry] = []

        if line.first == "[", let match = try? Self.lineRegex.wholeMatch(in: line) {

            // New header was found so output the previous buffer.
            if let pending {
                output.append(pending)
            }

            // Create a new buffer for the new log header.
            pending = ServerLogEntry(
                id: nextID,
                timestamp: Self.timestampFormatter.date(from: String(match.output.1)),
                type: ServerLogEntryType.from(String(match.output.2)),
                source: String(match.output.3),
                message: String(match.output.4)
            )

            nextID += 1

        } else if line.isNotEmpty {

            if pending != nil {

                // Continue the pending entry on a new line.
                pending?.message.append("\n")
                pending?.message.append(line)

            } else {

                // A non-header entry before any headers exist. This is malformed.
                // Malformed log entries should be handled as unknown.
                output.append(
                    ServerLogEntry(
                        id: nextID,
                        timestamp: nil,
                        type: .unknown,
                        source: nil,
                        message: line
                    )
                )
            }
            nextID += 1
        }

        // Empty lines are dropped.

        return output
    }

    mutating func flush() -> [ServerLogEntry] {
        guard let pending else { return [] }

        self.pending = nil

        return [pending]
    }
}
