//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum PlaybackBitrate: Int, CaseIterable, Displayable, Storable {
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

    // swiftlint:disable:next hard_coded_display_string
    var displayTitle: String {
        switch self {
        case .auto:
            L10n.auto
        case .max:
            L10n.maximum
        default:
            if let resolution {
                "\(resolution) - \(rawValue.formatted(.bitRate))"
            } else {
                rawValue.formatted(.bitRate)
            }
        }
    }

    // swiftlint:disable:next hard_coded_display_string
    var resolution: String? {
        switch self {
        case .mbps120, .mbps80:
            "4K"
        case .mbps60, .mbps40, .mbps20, .mbps15, .mbps10:
            "1080p"
        case .mbps8, .mbps6, .mbps4:
            "720p"
        case .mbps3, .kbps1500, .kbps720:
            "480p"
        case .kbps420:
            "360p"
        default:
            nil
        }
    }
}
