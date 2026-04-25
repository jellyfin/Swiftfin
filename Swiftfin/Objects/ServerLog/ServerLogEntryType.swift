//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// https://learn.microsoft.com/en-us/dotnet/core/extensions/logging/overview?tabs=command-line#log-level
enum ServerLogEntryType: String, CaseIterable, Displayable, SystemImageable {

    case trace = "TRC"
    case debug = "DBG"
    case info = "INF"
    case warning = "WRN"
    case error = "ERR"
    case critical = "CRT"
    case unknown = "UNK" // Catch for 'none' or new/unmapped types

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
        case .unknown:
            L10n.unknown
        }
    }

    var color: Color {
        switch self {
        case .unknown:
            .primary
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
        case .critical:
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
        case .critical:
            "xmark.octagon"
        case .unknown:
            "questionmark.circle"
        }
    }

    static func from(_ rawValue: String?) -> ServerLogEntryType {
        guard let rawValue else { return .unknown }

        return ServerLogEntryType(rawValue: rawValue) ?? .unknown
    }
}
