//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import VideoToolbox

enum VideoCodec: String, CaseIterable, Displayable, Defaults.Serializable {
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

    var videoFormatID: CMVideoCodecType? {
        switch self {
        case .av1:
            return kCMVideoCodecType_AV1
        case .dv:
            return nil // kCMVideoCodecType_DV
        case .dirac:
            return nil // kCMVideoCodecType_Dirac
        case .ffv1:
            return nil // No kCMVideoCodecType constant available
        case .flv1:
            return nil // No kCMVideoCodecType constant available
        case .h261:
            return nil // kCMVideoCodecType_H261
        case .h263:
            return kCMVideoCodecType_H263
        case .h264:
            return kCMVideoCodecType_H264
        case .hevc:
            return kCMVideoCodecType_HEVC
        case .mjpeg:
            return kCMVideoCodecType_JPEG
        case .mpeg1video:
            return kCMVideoCodecType_MPEG1Video
        case .mpeg2video:
            return kCMVideoCodecType_MPEG2Video
        case .mpeg4:
            return kCMVideoCodecType_MPEG4Video
        case .msmpeg4v1:
            return nil // No kCMVideoCodecType constant available
        case .msmpeg4v2:
            return nil // No kCMVideoCodecType constant available
        case .msmpeg4v3:
            return nil // No kCMVideoCodecType constant available
        case .prores:
            return kCMVideoCodecType_AppleProRes4444
        case .theora:
            return nil // No kCMVideoCodecType constant available
        case .vc1:
            return nil // kCMVideoCodecType_VC1
        case .vp8:
            return nil // kCMVideoCodecType_VP8
        case .vp9:
            return kCMVideoCodecType_VP9
        case .wmv1:
            return nil // No kCMVideoCodecType constant available
        case .wmv2:
            return nil // No kCMVideoCodecType constant available
        case .wmv3:
            return nil // No kCMVideoCodecType constant available
        }
    }

    var isSupported: Bool {
        guard let formatID = self.videoFormatID else {
            return false
        }

        var formatDescription: CMVideoFormatDescription?
        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: formatID,
            width: 1920,
            height: 1080,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )

        if status != noErr {
            print("CMVideoFormatDescriptionCreate error for \(self.rawValue): \(status)")
            return false
        }

        return formatDescription != nil
    }

    static func decodableCodecs() -> [VideoCodec] {
        VideoCodec.allCases.filter(\.isSupported)
    }
}
