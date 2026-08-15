//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension RepeatMode: Displayable, SystemImageable {

    var displayTitle: String {
        switch self {
        case .repeatNone:
            L10n.repeatOff
        case .repeatAll:
            L10n.repeatAll
        case .repeatOne:
            L10n.repeatOne
        }
    }

    var systemImage: String {
        switch self {
        case .repeatOne:
            "repeat.1"
        default:
            "repeat"
        }
    }
}
