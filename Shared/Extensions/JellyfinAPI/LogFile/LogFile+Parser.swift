//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension LogFile {

    enum Parser {

        /// Matches: `[YYYY-MM-DD HH:mm:ss.ms -HH:mm] [@@@] [##] Source.Path: Message`
        /// Example: `[2000-12-31 12:23:45.123 -06:00] [INF] [64] Jellyfin.Plugin: This is the message!`
        private static let systemLineRegex: Regex = /^\[([^\]]+)\] \[([A-Z]+)\] \[[^\]]+\] ([^:]+?): (.*)$/

        private static let logTimestampFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS XXX"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()

        private struct LogEntry {
            var timestamp: Date?
            var level: Entry.Level?
            var source: String?
            var message: String

            func build(id: Int) -> Entry {
                Entry(
                    id: id,
                    timestamp: timestamp,
                    level: level,
                    source: source,
                    message: message
                )
            }
        }

        static func parse(_ text: String) -> [Entry] {
            var entries: [Entry] = []
            var entry: LogEntry?

            func flush() {
                guard let entry else { return }
                entries.append(entry.build(id: entries.count))
            }

            for line in text.split(separator: "\n", omittingEmptySubsequences: false) {

                if let match = try? systemLineRegex.wholeMatch(in: line) {

                    flush()

                    entry = LogEntry(
                        timestamp: logTimestampFormatter.date(from: String(match.output.1)),
                        level: Entry.Level(rawValue: String(match.output.2)),
                        source: String(match.output.3),
                        message: String(match.output.4)
                    )
                } else if entry != nil {
                    entry?.message += "\n" + String(line)
                } else if !line.isEmpty {
                    entries.append(LogEntry(message: String(line)).build(id: entries.count))
                }
            }

            flush()
            return entries
        }
    }
}
