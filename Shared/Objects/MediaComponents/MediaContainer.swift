//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults

enum MediaContainer: String, CaseIterable, Codable, Displayable, Defaults.Serializable {

    case avi
    case flv
    case m4v
    case mkv
    case mov
    case mp4
    case mpegts
    case ts
    case threeG2 = "3g2"
    case threeGP = "3gp"
    case webm

    var displayTitle: String {
        switch self {
        case .avi:
            return "AVI"
        case .flv:
            return "FLV"
        case .m4v:
            return "M4V"
        case .mkv:
            return "MKV"
        case .mov:
            return "MOV"
        case .mp4:
            return "MP4"
        case .mpegts:
            return "MPEG-TS"
        case .ts:
            return "TS"
        case .threeG2:
            return "3G2"
        case .threeGP:
            return "3GP"
        case .webm:
            return "WEBM"
        }
    }
}
