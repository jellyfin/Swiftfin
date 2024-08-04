//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

enum MediaContainer: String, CaseIterable, Displayable, Defaults.Serializable {
    case threeG2 = "3g2"
    case threeGP = "3gp"
    case avi
    case m4v
    case mov
    case mp4
    case mpegts

    var displayTitle: String {
        switch self {
        case .threeG2:
            return "3G2"
        case .threeGP:
            return "3GP"
        case .avi:
            return "AVI"
        case .m4v:
            return "M4V"
        case .mov:
            return "MOV"
        case .mp4:
            return "MP4"
        case .mpegts:
            return "MPEG-TS"
        }
    }
}
