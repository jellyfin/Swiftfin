//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

enum PlaybackButtonType: String, CaseIterable, Displayable, Storable {

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
