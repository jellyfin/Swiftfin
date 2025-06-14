//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum MediaJumpInterval: Storable {

    case five
    case ten
    case fifteen
    case thirty
    case custom(interval: TimeInterval)

    var interval: TimeInterval {
        switch self {
        case .five: 5
        case .ten: 10
        case .fifteen: 15
        case .thirty: 30
        case let .custom(interval): interval
        }
    }

    var forwardSystemImage: String {
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

    var backwardSystemImage: String {
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
}
