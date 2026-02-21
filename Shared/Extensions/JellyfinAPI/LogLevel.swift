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
            .gray.opacity(0.7)
        case .debug:
            .gray
        case .information:
            .blue
        case .warning:
            .orange
        case .error:
            .red
        case .critical:
            .purple
        case .none:
            .secondary
        }
    }

    public var systemImage: String {
        switch self {
        case .trace:
            "ant"
        case .debug:
            "ladybug"
        case .information:
            "info.circle"
        case .warning:
            "exclamationmark.triangle"
        case .error:
            "exclamationmark.circle"
        case .critical:
            "xmark.octagon"
        case .none:
            "questionmark.circle"
        }
    }

    public var displayTitle: String {
        rawValue
    }
}
