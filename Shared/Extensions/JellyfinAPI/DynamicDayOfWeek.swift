//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DynamicDayOfWeek {

    var displayTitle: String {
        switch self {
        case .sunday:
            DayOfWeek.sunday.displayTitle ?? self.rawValue
        case .monday:
            DayOfWeek.monday.displayTitle ?? self.rawValue
        case .tuesday:
            DayOfWeek.tuesday.displayTitle ?? self.rawValue
        case .wednesday:
            DayOfWeek.wednesday.displayTitle ?? self.rawValue
        case .thursday:
            DayOfWeek.thursday.displayTitle ?? self.rawValue
        case .friday:
            DayOfWeek.friday.displayTitle ?? self.rawValue
        case .saturday:
            DayOfWeek.saturday.displayTitle ?? self.rawValue
        case .everyday:
            L10n.everyday
        case .weekday:
            L10n.weekday
        case .weekend:
            L10n.weekend
        }
    }
}
