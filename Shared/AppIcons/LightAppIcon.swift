//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum LightAppIcon: String, AppIcon {

    case blue
    case green
    case orange
    case red
    case yellow
    case jellyfin

    var displayTitle: String {
        switch self {
        case .blue:
            L10n.blue
        case .green:
            L10n.green
        case .orange:
            L10n.orange
        case .red:
            L10n.red
        case .yellow:
            L10n.yellow
        case .jellyfin:
            "Jellyfin"
        }
    }

    static let tag: String = "light"
}
