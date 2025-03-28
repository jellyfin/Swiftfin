//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension TaskTriggerType: Displayable, SystemImageable {
    var displayTitle: String {
        switch self {
        case .daily:
            return L10n.daily
        case .weekly:
            return L10n.weekly
        case .interval:
            return L10n.interval
        case .startup:
            return L10n.onApplicationStartup
        }
    }

    var systemImage: String {
        switch self {
        case .daily:
            return "clock"
        case .weekly:
            return "calendar"
        case .interval:
            return "timer"
        case .startup:
            return "power"
        }
    }
}
