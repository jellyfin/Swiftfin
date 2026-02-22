//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum MediaContainer: String, CaseIterable, Codable, Displayable, Storable {

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
            "AVI"
        case .flv:
            "FLV"
        case .m4v:
            "M4V"
        case .mkv:
            "MKV"
        case .mov:
            "MOV"
        case .mp4:
            "MP4"
        case .mpegts:
            "MPEG-TS"
        case .ts:
            "TS"
        case .threeG2:
            "3G2"
        case .threeGP:
            "3GP"
        case .webm:
            "WEBM"
        }
    }
}
