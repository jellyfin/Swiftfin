//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Identity parser: each chunk is emitted verbatim.
struct RawLineParser: LogParser<String> {

    let encoding: String.Encoding
    let delimiter: String

    init(encoding: String.Encoding = .utf8, delimiter: String = "\n") {
        self.encoding = encoding
        self.delimiter = delimiter
    }

    mutating func consume(chunk: String) -> [String] {
        [chunk]
    }

    mutating func flush() -> [String] {
        []
    }
}
