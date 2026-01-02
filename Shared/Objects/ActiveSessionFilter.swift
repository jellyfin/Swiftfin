//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum ActiveSessionFilter: String, CaseIterable, SystemImageable, Displayable, Storable {

    case all
    case active
    case inactive

    var displayTitle: String {
        switch self {
        case .all:
            return L10n.all
        case .active:
            return L10n.active
        case .inactive:
            return L10n.inactive
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "line.3.horizontal"
        case .active:
            return "play"
        case .inactive:
            return "play.slash"
        }
    }
}
