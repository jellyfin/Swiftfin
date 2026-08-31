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

    static func make(type: TaskTriggerInfoType) -> TaskTriggerInfo {
        switch type {
        case .dailyTrigger:
            .init(
                timeOfDayTicks: 0,
                type: type
            )
        case .weeklyTrigger:
            .init(
                dayOfWeek: .sunday,
                timeOfDayTicks: 0,
                type: type
            )
        case .intervalTrigger:
            .init(
                intervalTicks: Duration.hours(1).ticks,
                type: type
            )
        case .startupTrigger:
            .init(
                type: type
            )
        }
    }
}
