//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension TaskTriggerInfo {

    mutating func reset() {
        switch type {
        case .dailyTrigger:
            timeOfDayTicks = 0
            dayOfWeek = nil
            intervalTicks = nil
        case .weeklyTrigger:
            timeOfDayTicks = 0
            dayOfWeek = .sunday
            intervalTicks = nil
        case .intervalTrigger:
            timeOfDayTicks = nil
            dayOfWeek = nil
            intervalTicks = Duration.hours(1).ticks
        default:
            type = .startupTrigger
            timeOfDayTicks = nil
            dayOfWeek = nil
            intervalTicks = nil
        }
    }
}
