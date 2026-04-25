//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Turns raw text chunks (split on a delimiter) into typed elements.
protocol LogParser<Element> {

    associatedtype Element

    /// Encoding used to decode bytes from the source file.
    var encoding: String.Encoding { get }

    /// Byte sequence that separates chunks in the source file.
    /// Example:
    /// - "/n" for a new line separated file
    var delimiter: String { get }

    /// Consume one chunk, returning any elements that completed as a result.
    mutating func consume(chunk: String) -> [Element]

    /// Emit any element still pending in internal state. Called once at end-of-file.
    mutating func flush() -> [Element]
}
