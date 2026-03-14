//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DynamicDayOfWeek {

    var displayTitle: String {
        switch self {
        case .sunday:
            DayOfWeek.sunday.displayTitle
        case .monday:
            DayOfWeek.monday.displayTitle
        case .tuesday:
            DayOfWeek.tuesday.displayTitle
        case .wednesday:
            DayOfWeek.wednesday.displayTitle
        case .thursday:
            DayOfWeek.thursday.displayTitle
        case .friday:
            DayOfWeek.friday.displayTitle
        case .saturday:
            DayOfWeek.saturday.displayTitle
        case .everyday:
            L10n.everyday
        case .weekday:
            L10n.weekday
        case .weekend:
            L10n.weekend
        }
    }
}
