//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults

enum BitrateSelection: String, CaseIterable, Defaults.Serializable, Displayable {

    case auto
    case mbps120
    case mbps80
    case mbps60
    case mbps40
    case mbps20
    case mbps15
    case mbps10
    case mbps8
    case mbps6
    case mbps4
    case mbps3
    case kbps1500
    case kbps720
    case kbps420

    var displayTitle: String {
        switch self {
        case .auto:
            return L10n.bitrateAuto
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

    var rawValue: Int {
        switch self {
        case .auto:
            return 360_000_000
        case .mbps120:
            return 120_000_000
        case .mbps80:
            return 80_000_000
        case .mbps60:
            return 60_000_000
        case .mbps40:
            return 40_000_000
        case .mbps20:
            return 20_000_000
        case .mbps15:
            return 15_000_000
        case .mbps10:
            return 10_000_000
        case .mbps8:
            return 8_000_000
        case .mbps6:
            return 6_000_000
        case .mbps4:
            return 4_000_000
        case .mbps3:
            return 3_000_000
        case .kbps1500:
            return 1_500_000
        case .kbps720:
            return 720_000
        case .kbps420:
            return 420_000
        }
    }
}
