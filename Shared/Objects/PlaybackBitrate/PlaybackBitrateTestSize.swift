//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

enum PlaybackBitrateTestSize: Int, CaseIterable, Defaults.Serializable, Displayable {
    case longest = 10_000_000
    case longer = 7_500_000
    case standard = 5_000_000
    case shorter = 2_500_000
    case shortest = 1_000_000

    var displayTitle: String {
        switch self {
        case .longest:
            return L10n.longest
        case .longer:
            return L10n.longer
        case .standard:
            return L10n.standard
        case .shorter:
            return L10n.shorter
        case .shortest:
            return L10n.shortest
        }
    }
}
