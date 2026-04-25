//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Parses Jellyfin system log files into `ServerLogEntry` records.
///
/// Format: `[2000-12-31 12:23:45.123 -06:00] [INF] [64] Source: message`.
/// Lines that don't match the header pattern attach to the previous entry
/// (stack traces, exception bodies).
struct ServerLogParser: LogParser<ServerLogEntry> {

    let encoding: String.Encoding = .utf8
    let delimiter: String = "\n"

    private static let lineRegex: Regex = /^\[([^\]]+)\] \[([A-Z]+)\] \[[^\]]+\] ([^:]+?): (.*)$/

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS XXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private var pending: ServerLogEntry?
    private var nextID: Int = 0

    mutating func consume(chunk line: String) -> [ServerLogEntry] {
        var output: [ServerLogEntry] = []

        // Header lines always start with `[` so look for this first.
        // - This prevents the expensive REGEX until we actually need it.
        if line.first == "[", let match = try? Self.lineRegex.wholeMatch(in: line) {

            if let pending {
                output.append(pending)
            }

            pending = ServerLogEntry(
                id: nextID,
                timestamp: Self.timestampFormatter.date(from: String(match.output.1)),
                type: ServerLogEntryType.from(String(match.output.2)),
                source: String(match.output.3),
                message: String(match.output.4)
            )
            nextID += 1

        } else if pending != nil {

            pending!.message.append("\n")
            pending!.message.append(line)

        } else if !line.isEmpty {

            // Orphan line before any header has been seen.
            output.append(
                ServerLogEntry(
                    id: nextID,
                    timestamp: nil,
                    type: nil,
                    source: nil,
                    message: line
                )
            )
            nextID += 1
        }

        return output
    }

    mutating func flush() -> [ServerLogEntry] {
        guard let pending else { return [] }
        self.pending = nil
        return [pending]
    }
}
