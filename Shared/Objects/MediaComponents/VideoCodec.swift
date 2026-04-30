//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum VideoCodec: String, CaseIterable, Codable, Displayable, Storable {

    case av1
    case dv
    case dirac
    case ffv1
    case flv1
    case h261
    case h263
    case h264
    case hevc
    case mjpeg
    case mpeg1video
    case mpeg2video
    case mpeg4
    case msmpeg4v1
    case msmpeg4v2
    case msmpeg4v3
    case prores
    case theora
    case vc1
    case vp8
    case vp9
    case vvc
    case wmv1
    case wmv2
    case wmv3

    var displayTitle: String {
        switch self {
        case .av1:
            L10n.av1
        case .dv:
            L10n.dv
        case .dirac:
            L10n.dirac
        case .ffv1:
            L10n.ffv1
        case .flv1:
            L10n.flv1
        case .h261:
            L10n.h261
        case .h263:
            L10n.h263
        case .h264:
            L10n.h264
        case .hevc:
            L10n.hevc
        case .mjpeg:
            L10n.mjpeg
        case .mpeg1video:
            L10n.mpeg1Video
        case .mpeg2video:
            L10n.mpeg2Video
        case .mpeg4:
            L10n.mpeg4
        case .msmpeg4v1:
            L10n.msMpeg4V1
        case .msmpeg4v2:
            L10n.msMpeg4V2
        case .msmpeg4v3:
            L10n.msMpeg4V3
        case .prores:
            L10n.proRes
        case .theora:
            L10n.theora
        case .vc1:
            L10n.vc1
        case .vp8:
            L10n.vp8
        case .vp9:
            L10n.vp9
        case .vvc:
            L10n.vvc
        case .wmv1:
            L10n.wmv1
        case .wmv2:
            L10n.wmv2
        case .wmv3:
            L10n.wmv3
        }
    }
}
