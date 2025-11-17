//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension VideoRangeType: Displayable {
    /// Dolby Vision is a proper noun so it is not localized
    var displayTitle: String {
        switch self {
        case .unknown:
            return L10n.unknown
        case .sdr:
            return "SDR"
        case .hdr10:
            return "HDR10"
        case .hlg:
            return "HLG"
        case .dovi:
            return "Dolby Vision"
        case .doviWithEL:
            return "Dolby Vision with Enhancement Layer"
        case .doviWithELHDR10Plus:
            return "Dolby Vision with Enhancement Layer / HDR10+"
        case .doviWithHDR10:
            return "Dolby Vision / HDR10"
        case .doviWithHDR10Plus:
            return "Dolby Vision / HDR10+"
        case .doviWithHLG:
            return "Dolby Vision / HLG"
        case .doviInvalid:
            return "Invalid Dobly Vision"
        case .doviWithSDR:
            return "Dolby Vision / SDR"
        case .hdr10Plus:
            return "HDR10+"
        }
    }

    /// Returns `true` if the video format is HDR (including Dolby Vision).
    var isHDR: Bool {
        switch self {
        case .hdr10, .hlg, .hdr10Plus, .dovi, .doviWithHDR10, .doviWithHLG, .doviWithSDR:
            return true
        default:
            return false
        }
    }

    /// Returns `true` if the video format is Dolby Vision.
    var isDolbyVision: Bool {
        switch self {
        case .dovi, .doviWithHDR10, .doviWithHLG, .doviWithSDR:
            return true
        default:
            return false
        }
    }
}
