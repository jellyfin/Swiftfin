//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum PlaybackSpeed: Double, CaseIterable, Defaults.Serializable, Displayable {

    case quarter = 0.25
    case half = 0.5
    case threeQuarter = 0.75
    case one = 1.0
    case oneQuarter = 1.25
    case oneHalf = 1.5
    case oneThreeQuarter = 1.75
    case two = 2.0

    var displayTitle: String {
        DoublePlaybackRateFormatStyle().format(rawValue)
    }
}
