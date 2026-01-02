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
    case wmv1
    case wmv2
    case wmv3

    var displayTitle: String {
        switch self {
        case .av1:
            return "AV1"
        case .dv:
            return "DV"
        case .dirac:
            return "Dirac"
        case .ffv1:
            return "FFV1"
        case .flv1:
            return "FLV1"
        case .h261:
            return "H.261"
        case .h263:
            return "H.263"
        case .h264:
            return "H.264"
        case .hevc:
            return "HEVC"
        case .mjpeg:
            return "MJPEG"
        case .mpeg1video:
            return "MPEG-1 Video"
        case .mpeg2video:
            return "MPEG-2 Video"
        case .mpeg4:
            return "MPEG-4"
        case .msmpeg4v1:
            return "MS MPEG-4 v1"
        case .msmpeg4v2:
            return "MS MPEG-4 v2"
        case .msmpeg4v3:
            return "MS MPEG-4 v3"
        case .prores:
            return "ProRes"
        case .theora:
            return "Theora"
        case .vc1:
            return "VC-1"
        case .vp8:
            return "VP8"
        case .vp9:
            return "VP9"
        case .wmv1:
            return "WMV1"
        case .wmv2:
            return "WMV2"
        case .wmv3:
            return "WMV3"
        }
    }
}
