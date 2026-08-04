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
    case mbps2 = 2_000_000
    case kbps1500 = 1_500_000
    case mbps1 = 1_000_000
    case kbps720 = 720_000
    case kbps420 = 420_000
    case kbps320 = 320_000
    case kbps256 = 256_000
    case kbps192 = 192_000
    case kbps128 = 128_000
    case kbps96 = 96000
    case kbps64 = 64000

    var displayTitle: String {
        switch self {
        case .auto:
            L10n.auto
        case .max:
            L10n.maximum
        default:
            rawValue.formatted(.bitRate)
        }
    }

    /// Bitrates for audio files
    static let audioBitrates: [PlaybackBitrate] = [
        .auto,
        .mbps2,
        .kbps1500,
        .mbps1,
        .kbps320,
        .kbps256,
        .kbps192,
        .kbps128,
        .kbps96,
        .kbps64,
    ]

    /// Bitrates for video files
    static let videoBitrates: [PlaybackBitrate] = [
        .auto,
        .max,
        .mbps120,
        .mbps80,
        .mbps60,
        .mbps40,
        .mbps20,
        .mbps15,
        .mbps10,
        .mbps8,
        .mbps6,
        .mbps4,
        .mbps3,
        .kbps1500,
        .kbps720,
        .kbps420,
    ]
}

extension PlaybackBitrate {

    /// Find the closest bitrate for an unknown input bitrate int
    init(for bitrate: Int, in bitrates: [PlaybackBitrate] = PlaybackBitrate.allCases) {
        let selectable = bitrates.filter { $0 != .auto }

        self = selectable
            .filter { $0.rawValue <= bitrate }
            .max(by: { $0.rawValue < $1.rawValue })
            ?? selectable.min(by: { $0.rawValue < $1.rawValue })
            ?? .auto
    }
}
