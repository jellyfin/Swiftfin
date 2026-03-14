//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum MediaJumpInterval: CaseIterable, Displayable, Hashable, RawRepresentable, Storable, SystemImageable {

    typealias RawValue = Duration

    case five
    case ten
    case fifteen
    case thirty
    case custom(interval: Duration)

    init(rawValue: Duration) {
        switch rawValue {
        case .seconds(5):
            self = .five
        case .seconds(10):
            self = .ten
        case .seconds(15):
            self = .fifteen
        case .seconds(30):
            self = .thirty
        default:
            self = .custom(interval: rawValue)
        }
    }

    var rawValue: Duration {
        switch self {
        case .five:
            .seconds(5)
        case .ten:
            .seconds(10)
        case .fifteen:
            .seconds(15)
        case .thirty:
            .seconds(30)
        case let .custom(interval):
            interval
        }
    }

    var displayTitle: String {
        rawValue.formatted(.minuteSecondsNarrow)
    }

    var systemImage: String {
        switch self {
        case .thirty:
            "goforward.30"
        case .fifteen:
            "goforward.15"
        case .ten:
            "goforward.10"
        case .five:
            "goforward.5"
        case .custom:
            "goforward"
        }
    }

    var secondarySystemImage: String {
        switch self {
        case .thirty:
            "gobackward.30"
        case .fifteen:
            "gobackward.15"
        case .ten:
            "gobackward.10"
        case .five:
            "gobackward.5"
        case .custom:
            "gobackward"
        }
    }

    static var allCases: [MediaJumpInterval] {
        [.five, .ten, .fifteen, .thirty]
    }
}
