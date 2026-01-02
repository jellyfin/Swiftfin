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
            return L10n.daily
        case .weeklyTrigger:
            return L10n.weekly
        case .intervalTrigger:
            return L10n.interval
        case .startupTrigger:
            return L10n.onApplicationStartup
        }
    }

    var systemImage: String {
        switch self {
        case .dailyTrigger:
            return "clock"
        case .weeklyTrigger:
            return "calendar"
        case .intervalTrigger:
            return "timer"
        case .startupTrigger:
            return "power"
        }
    }
}
