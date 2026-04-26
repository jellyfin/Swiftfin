//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Parse logs into individual lines.
struct RawLogParser: LogParser<String> {

    let encoding: String.Encoding
    let delimiter: String

    init(encoding: String.Encoding = .utf8, delimiter: String = "\n") {
        self.encoding = encoding
        self.delimiter = delimiter
    }

    /// Treat every new line as a record.
    func isHeader(line: String) -> Bool {
        true
    }

    mutating func read(chunk: String) -> [String] {
        [chunk]
    }

    mutating func flush() -> [String] {
        []
    }
}
