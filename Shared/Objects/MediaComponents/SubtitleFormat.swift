//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UniformTypeIdentifiers

enum SubtitleFormat: String, CaseIterable, Codable, Displayable, Storable {

    case ass
    case cc_dec
    case dvdsub
    case dvbsub
    case jacosub
    case libzvbi_teletextdec
    case mov_text
    case mpl2
    case pjs
    case pgssub
    case realtext
    case sami
    case ssa
    case subrip
    case subviewer
    case subviewer1
    case text
    case ttml
    case vplayer
    case vtt
    case xsub

    init?(url: URL) {
        let fileExtension = url.pathExtension.lowercased()

        if let value = SubtitleFormat.allCases.first(where: { $0.fileExtension == fileExtension }) {
            self = value
        } else {
            return nil
        }
    }

    var displayTitle: String {
        switch self {
        case .ass:
            return "ASS"
        case .cc_dec:
            return "EIA-608"
        case .dvdsub:
            return "DVD Subtitle"
        case .dvbsub:
            return "DVB Subtitle"
        case .jacosub:
            return "Jacosub"
        case .libzvbi_teletextdec:
            return "DVB Teletext"
        case .mov_text:
            return "MPEG-4 Timed Text"
        case .mpl2:
            return "MPL2"
        case .pjs:
            return "Phoenix Subtitle"
        case .pgssub:
            return "PGS Subtitle"
        case .realtext:
            return "RealText"
        case .sami:
            return "SMI"
        case .ssa:
            return "SSA"
        case .subrip:
            return "SRT"
        case .subviewer:
            return "SubViewer"
        case .subviewer1:
            return "SubViewer1"
        case .text:
            return "TXT"
        case .ttml:
            return "TTML"
        case .vplayer:
            return "VPlayer"
        case .vtt:
            return "WebVTT"
        case .xsub:
            return "XSUB"
        }
    }

    /// Gets the file extension for this subtitle format
    var fileExtension: String {
        switch self {
        case .ass:
            return "ass"
        case .cc_dec:
            return "608"
        case .dvdsub:
            return "sub"
        case .dvbsub:
            return "dvbsub"
        case .jacosub:
            return "jss"
        case .libzvbi_teletextdec:
            return "txt"
        case .mov_text:
            return "tx3g"
        case .mpl2:
            return "mpl"
        case .pjs:
            return "pjs"
        case .pgssub:
            return "sup"
        case .realtext:
            return "rt"
        case .sami:
            return "smi"
        case .ssa:
            return "ssa"
        case .subrip:
            return "srt"
        case .subviewer:
            return "sub"
        case .subviewer1:
            return "sub"
        case .text:
            return "txt"
        case .ttml:
            return "ttml"
        case .vplayer:
            return "txt"
        case .vtt:
            return "vtt"
        case .xsub:
            return "xsub"
        }
    }

    /// Gets the appropriate UTType for this subtitle format
    var utType: UTType? {
        switch self {
        case .libzvbi_teletextdec, .text, .vplayer:
            UTType.plainText
        default:
            UTType(filenameExtension: fileExtension)
        }
    }

    /// Whether this format is a text-based subtitle
    var isText: Bool {
        switch self {
        case .ass, .cc_dec, .jacosub, .libzvbi_teletextdec, .mov_text,
             .mpl2, .pjs, .realtext, .sami, .ssa, .subrip, .subviewer,
             .subviewer1, .text, .ttml, .vplayer, .vtt:
            return true
        case .dvdsub, .dvbsub, .pgssub, .xsub:
            return false
        }
    }
}
