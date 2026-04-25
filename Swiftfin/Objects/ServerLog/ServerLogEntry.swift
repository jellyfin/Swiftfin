//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct ServerLogEntry: Identifiable, Hashable {

    let id: Int
    let timestamp: Date?
    let type: ServerLogEntryType?
    let source: String?
    var message: String

    /// Single-line copyable text for the entry
    var copiedText: String {
        var components: [String] = []

        if let timestamp {
            components.append("[\(timestamp.formatted(.iso8601))]")
        }

        if let type {
            components.append("[\(type.rawValue)]")
        }

        if let source {
            components.append("\(source):")
        }

        components.append(message)

        return components.joined(separator: " ")
    }
}
