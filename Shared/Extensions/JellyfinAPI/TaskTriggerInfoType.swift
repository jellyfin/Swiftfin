//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension TaskTriggerInfoType: Displayable, SystemImageable {
    var displayTitle: String {
        switch self {
        case .dailyTrigger:
            L10n.daily
        case .weeklyTrigger:
            L10n.weekly
        case .intervalTrigger:
            L10n.interval
        case .startupTrigger:
            L10n.onApplicationStartup
        }
    }

    var systemImage: String {
        switch self {
        case .dailyTrigger:
            "clock"
        case .weeklyTrigger:
            "calendar"
        case .intervalTrigger:
            "timer"
        case .startupTrigger:
            "power"
        }
    }
}
