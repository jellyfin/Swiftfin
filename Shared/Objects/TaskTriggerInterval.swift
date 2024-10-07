//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

enum TaskTriggerInterval: TimeInterval, CaseIterable, Identifiable {
    case fifteenMinutes = 9_000_000_000
    case thirtyMinutes = 18_000_000_000
    case fortyFiveMinutes = 27_000_000_000
    case oneHour = 36_000_000_000
    case twoHours = 72_000_000_000
    case threeHours = 108_000_000_000
    case fourHours = 144_000_000_000
    case sixHours = 216_000_000_000
    case eightHours = 288_000_000_000
    case twelveHours = 432_000_000_000
    case twentyFourHours = 864_000_000_000

    /// Use the number of ticks as the Id
    var id: TimeInterval {
        self.rawValue
    }

    /// Number of seconds for the interval (1 tick = 0.1 microseconds)
    var seconds: Int {
        Int(rawValue / 10_000_000)
    }

    var displayTitle: String {
        switch self {
        case .fifteenMinutes:
            return L10n.intervalMinutes(15)
        case .thirtyMinutes:
            return L10n.intervalMinutes(30)
        case .fortyFiveMinutes:
            return L10n.intervalMinutes(45)
        case .oneHour:
            return L10n.intervalHours(1)
        case .twoHours:
            return L10n.intervalHours(2)
        case .threeHours:
            return L10n.intervalHours(3)
        case .fourHours:
            return L10n.intervalHours(4)
        case .sixHours:
            return L10n.intervalHours(6)
        case .eightHours:
            return L10n.intervalHours(8)
        case .twelveHours:
            return L10n.intervalHours(12)
        case .twentyFourHours:
            return L10n.intervalHours(24)
        }
    }
}
