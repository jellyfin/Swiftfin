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
    let level: Level?
    let source: String?
    let message: String

    /// Single-line representation of the entry suitable for clipboard copy.
    var clipboardText: String {
        var parts: [String] = []
        if let timestamp {
            parts.append("[\(timestamp.formatted(.iso8601))]")
        }
        if let level {
            parts.append("[\(level.rawValue)]")
        }
        if let source {
            parts.append("\(source):")
        }
        parts.append(message)
        return parts.joined(separator: " ")
    }

    enum Level: String, CaseIterable, Displayable, SystemImageable {

        case trace = "TRC"
        case debug = "DBG"
        case info = "INF"
        case warning = "WRN"
        case error = "ERR"
        case critical = "CRT"
        case fatal = "FTL"

        var displayTitle: String {
            switch self {
            case .trace:
                L10n.trace
            case .debug:
                L10n.debug
            case .info:
                L10n.information
            case .warning:
                L10n.warning
            case .error:
                L10n.error
            case .critical:
                L10n.critical
            case .fatal:
                L10n.fatal
            }
        }

        var color: Color {
            switch self {
            case .trace:
                .gray.opacity(0.7)
            case .debug:
                .gray
            case .info:
                .blue
            case .warning:
                .orange
            case .error:
                .red
            case .critical, .fatal:
                .purple
            }
        }

        var systemImage: String {
            switch self {
            case .trace:
                "ant"
            case .debug:
                "ladybug"
            case .info:
                "info.circle"
            case .warning:
                "exclamationmark.triangle"
            case .error:
                "exclamationmark.circle"
            case .critical, .fatal:
                "xmark.octagon"
            }
        }
    }
}
