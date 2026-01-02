//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import UIKit

enum VideoPlayerJumpLength: Int, CaseIterable, Defaults.Serializable, Displayable {

    case five = 5
    case ten = 10
    case fifteen = 15
    case thirty = 30

    // TODO: formatter for locale?
    var displayTitle: String {
        "\(rawValue)s"
    }

    var forwardImageLabel: String {
        switch self {
        case .thirty:
            return "goforward.30"
        case .fifteen:
            return "goforward.15"
        case .ten:
            return "goforward.10"
        case .five:
            return "goforward.5"
        }
    }

    var backwardImageLabel: String {
        switch self {
        case .thirty:
            return "gobackward.30"
        case .fifteen:
            return "gobackward.15"
        case .ten:
            return "gobackward.10"
        case .five:
            return "gobackward.5"
        }
    }
}
