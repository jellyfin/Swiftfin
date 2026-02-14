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
    /// Dolby Vision is a proper noun so it is not localized
    var displayTitle: String {
        switch self {
        case .unknown:
            L10n.unknown
        case .sdr:
            "SDR"
        case .hdr10:
            "HDR10"
        case .hlg:
            "HLG"
        case .dovi:
            "Dolby Vision"
        case .doviWithEL:
            "Dolby Vision with Enhancement Layer"
        case .doviWithELHDR10Plus:
            "Dolby Vision with Enhancement Layer / HDR10+"
        case .doviWithHDR10:
            "Dolby Vision / HDR10"
        case .doviWithHDR10Plus:
            "Dolby Vision / HDR10+"
        case .doviWithHLG:
            "Dolby Vision / HLG"
        case .doviInvalid:
            "Invalid Dobly Vision"
        case .doviWithSDR:
            "Dolby Vision / SDR"
        case .hdr10Plus:
            "HDR10+"
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
