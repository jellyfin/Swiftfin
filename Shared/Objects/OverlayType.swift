//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum OverlayType: String, CaseIterable, Storable {

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

enum PlaybackButtonType: String, CaseIterable, Displayable, Storable {

    case large
    case compact

    var displayTitle: String {
        switch self {
        case .large:
            return L10n.large
        case .compact:
            return L10n.compact
        }
    }
}
