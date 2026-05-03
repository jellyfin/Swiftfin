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
            L10n.avi
        case .flv:
            L10n.flv
        case .m4v:
            L10n.m4v
        case .mkv:
            L10n.mkv
        case .mov:
            L10n.mov
        case .mp4:
            L10n.mp4
        case .mpegts:
            L10n.mpegTS
        case .ts:
            L10n.ts
        case .threeG2:
            L10n.threeG2
        case .threeGP:
            L10n.threeGP
        case .webm:
            L10n.webm
        }
    }
}
