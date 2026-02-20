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
            "AV1"
        case .dv:
            "DV"
        case .dirac:
            "Dirac"
        case .ffv1:
            "FFV1"
        case .flv1:
            "FLV1"
        case .h261:
            "H.261"
        case .h263:
            "H.263"
        case .h264:
            "H.264"
        case .hevc:
            "HEVC"
        case .mjpeg:
            "MJPEG"
        case .mpeg1video:
            "MPEG-1 Video"
        case .mpeg2video:
            "MPEG-2 Video"
        case .mpeg4:
            "MPEG-4"
        case .msmpeg4v1:
            "MS MPEG-4 v1"
        case .msmpeg4v2:
            "MS MPEG-4 v2"
        case .msmpeg4v3:
            "MS MPEG-4 v3"
        case .prores:
            "ProRes"
        case .theora:
            "Theora"
        case .vc1:
            "VC-1"
        case .vp8:
            "VP8"
        case .vp9:
            "VP9"
        case .vvc:
            "VVC"
        case .wmv1:
            "WMV1"
        case .wmv2:
            "WMV2"
        case .wmv3:
            "WMV3"
        }
    }
}
