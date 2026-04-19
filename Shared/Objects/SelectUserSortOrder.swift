//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum SelectUserSortOrder: String, CaseIterable, Displayable, Storable, SystemImageable {

    case name
    case lastSeen

    var displayTitle: String {
        switch self {
        case .name:
            L10n.name
        case .lastSeen:
            L10n.lastSeen
        }
    }

    var systemImage: String {
        switch self {
        case .name:
            "textformat.abc"
        case .lastSeen:
            "clock.fill"
        }
    }
}
