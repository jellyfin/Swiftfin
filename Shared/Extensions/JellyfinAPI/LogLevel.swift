//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension LogLevel: SystemImageable, Displayable {
    public var color: Color {
        switch self {
        case .trace:
            return .gray.opacity(0.7)
        case .debug:
            return .gray
        case .information:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .purple
        case .none:
            return .secondary
        }
    }

    public var systemImage: String {
        switch self {
        case .trace:
            return "ant"
        case .debug:
            return "ladybug"
        case .information:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "exclamationmark.circle"
        case .critical:
            return "xmark.octagon"
        case .none:
            return "questionmark.circle"
        }
    }

    public var displayTitle: String {
        rawValue
    }
}
