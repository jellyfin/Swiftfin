//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum InvertedLightAppIcon: String, AppIcon {

    case blue
    case green
    case orange
    case red
    case yellow
    case jellyfin

    var displayTitle: String {
        switch self {
        case .blue:
            return L10n.blue
        case .green:
            return L10n.green
        case .orange:
            return L10n.orange
        case .red:
            return L10n.red
        case .yellow:
            return L10n.yellow
        case .jellyfin:
            return "Jellyfin"
        }
    }

    static let tag: String = "invertedLight"
}
