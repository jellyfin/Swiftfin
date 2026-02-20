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
            "ASS"
        case .cc_dec:
            "EIA-608"
        case .dvdsub:
            "DVD Subtitle"
        case .dvbsub:
            "DVB Subtitle"
        case .jacosub:
            "Jacosub"
        case .libzvbi_teletextdec:
            "DVB Teletext"
        case .mov_text:
            "MPEG-4 Timed Text"
        case .mpl2:
            "MPL2"
        case .pjs:
            "Phoenix Subtitle"
        case .pgssub:
            "PGS Subtitle"
        case .realtext:
            "RealText"
        case .sami:
            "SMI"
        case .ssa:
            "SSA"
        case .subrip:
            "SRT"
        case .subviewer:
            "SubViewer"
        case .subviewer1:
            "SubViewer1"
        case .text:
            "TXT"
        case .ttml:
            "TTML"
        case .vplayer:
            "VPlayer"
        case .vtt:
            "WebVTT"
        case .xsub:
            "XSUB"
        }
    }

    /// Gets the file extension for this subtitle format
    var fileExtension: String {
        switch self {
        case .ass:
            "ass"
        case .cc_dec:
            "608"
        case .dvdsub:
            "sub"
        case .dvbsub:
            "dvbsub"
        case .jacosub:
            "jss"
        case .libzvbi_teletextdec:
            "txt"
        case .mov_text:
            "tx3g"
        case .mpl2:
            "mpl"
        case .pjs:
            "pjs"
        case .pgssub:
            "sup"
        case .realtext:
            "rt"
        case .sami:
            "smi"
        case .ssa:
            "ssa"
        case .subrip:
            "srt"
        case .subviewer:
            "sub"
        case .subviewer1:
            "sub"
        case .text:
            "txt"
        case .ttml:
            "ttml"
        case .vplayer:
            "txt"
        case .vtt:
            "vtt"
        case .xsub:
            "xsub"
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
            true
        case .dvdsub, .dvbsub, .pgssub, .xsub:
            false
        }
    }
}
