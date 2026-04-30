//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension VideoRangeType: Displayable {

    // swiftlint:disable:next hard_coded_display_string
    var displayTitle: String {
        switch self {
        case .unknown:
            L10n.unknown
        case .sdr:
            L10n.sdr
        case .hdr10:
            L10n.hdr10
        case .hlg:
            L10n.hlg
        case .dovi:
            L10n.dolbyVision
        case .doviWithEL:
            L10n.withEnhancementLayer(L10n.dolbyVision)
        case .doviWithELHDR10Plus:
            "\(L10n.withEnhancementLayer(L10n.dolbyVision)) / \(L10n.hdr10Plus)"
        case .doviWithHDR10:
            "\(L10n.dolbyVision) / \(L10n.hdr10)"
        case .doviWithHDR10Plus:
            "\(L10n.dolbyVision) / \(L10n.hdr10Plus)"
        case .doviWithHLG:
            "\(L10n.dolbyVision) / \(L10n.hlg)"
        case .doviInvalid:
            L10n.invalidX(L10n.dolbyVision)
        case .doviWithSDR:
            "\(L10n.dolbyVision) / \(L10n.sdr)"
        case .hdr10Plus:
            L10n.hdr10Plus
        }
    }

    /// Returns `true` if the video format is HDR (including Dolby Vision).
    var isHDR: Bool {
        switch self {
        case .sdr, .doviInvalid, .unknown:
            false
        default:
            true
        }
    }

    /// Returns `true` if the video format is Dolby Vision.
    var isDolbyVision: Bool {
        switch self {
        case .dovi, .doviWithEL, .doviWithHLG, .doviWithSDR, .doviWithHDR10, .doviWithHDR10Plus, .doviWithELHDR10Plus:
            true
        default:
            false
        }
    }
}
