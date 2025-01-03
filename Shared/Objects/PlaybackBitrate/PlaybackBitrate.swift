//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

enum PlaybackBitrate: Int, CaseIterable, Defaults.Serializable, Displayable {
    case auto = 0
    case max = 360_000_000
    case mbps120 = 120_000_000
    case mbps80 = 80_000_000
    case mbps60 = 60_000_000
    case mbps40 = 40_000_000
    case mbps20 = 20_000_000
    case mbps15 = 15_000_000
    case mbps10 = 10_000_000
    case mbps8 = 8_000_000
    case mbps6 = 6_000_000
    case mbps4 = 4_000_000
    case mbps3 = 3_000_000
    case kbps1500 = 1_500_000
    case kbps720 = 720_000
    case kbps420 = 420_000

    var displayTitle: String {
        switch self {
        case .auto:
            return L10n.bitrateAuto
        case .max:
            return L10n.bitrateMax
        case .mbps120:
            return L10n.bitrateMbps120
        case .mbps80:
            return L10n.bitrateMbps80
        case .mbps60:
            return L10n.bitrateMbps60
        case .mbps40:
            return L10n.bitrateMbps40
        case .mbps20:
            return L10n.bitrateMbps20
        case .mbps15:
            return L10n.bitrateMbps15
        case .mbps10:
            return L10n.bitrateMbps10
        case .mbps8:
            return L10n.bitrateMbps8
        case .mbps6:
            return L10n.bitrateMbps6
        case .mbps4:
            return L10n.bitrateMbps4
        case .mbps3:
            return L10n.bitrateMbps3
        case .kbps1500:
            return L10n.bitrateKbps1500
        case .kbps720:
            return L10n.bitrateKbps720
        case .kbps420:
            return L10n.bitrateKbps420
        }
    }
}
