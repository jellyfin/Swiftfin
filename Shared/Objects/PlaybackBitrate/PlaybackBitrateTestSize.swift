//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

enum PlaybackBitrateTestSize: Int, CaseIterable, Defaults.Serializable, Displayable {
    case largest = 10_000_000
    case larger = 7_500_000
    case regular = 5_000_000
    case smaller = 2_500_000
    case smallest = 1_000_000

    var displayTitle: String {
        switch self {
        case .largest:
            return L10n.largest
        case .larger:
            return L10n.larger
        case .regular:
            return L10n.regular
        case .smaller:
            return L10n.smaller
        case .smallest:
            return L10n.smallest
        }
    }
}
