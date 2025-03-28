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
        case .dOVIWithHDR10:
            return "Dolby Vision / HDR10"
        case .dOVIWithHLG:
            return "Dolby Vision / HLG"
        case .dOVIWithSDR:
            return "Dolby Vision / SDR"
        case .hDR10Plus:
            return "HDR10+"
        }
    }

    /// Returns `true` if the video format is HDR (including Dolby Vision).
    var isHDR: Bool {
        switch self {
        case .unknown, .sdr:
            return false
        case .hdr10, .hlg, .dovi, .dOVIWithHDR10, .dOVIWithHLG, .dOVIWithSDR, .hDR10Plus:
            return true
        }
    }

    /// Returns `true` if the video format is Dolby Vision.
    var isDolbyVision: Bool {
        switch self {
        case .dovi, .dOVIWithHDR10, .dOVIWithHLG, .dOVIWithSDR:
            return true
        default:
            return false
        }
    }
}
