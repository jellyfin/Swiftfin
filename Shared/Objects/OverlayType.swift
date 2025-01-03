//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum OverlayType: String, CaseIterable, Defaults.Serializable {

    case normal
    case compact

    var label: String {
        switch self {
        case .normal:
            return L10n.normal
        case .compact:
            return L10n.compact
        }
    }
}

enum PlaybackButtonType: String, CaseIterable, Displayable, Defaults.Serializable {

    case large
    case compact

    var displayTitle: String {
        switch self {
        case .large:
            return "Large"
        case .compact:
            return L10n.compact
        }
    }
}
