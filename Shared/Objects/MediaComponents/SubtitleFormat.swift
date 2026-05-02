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
            L10n.ass
        case .cc_dec:
            L10n.eia608
        case .dvdsub:
            L10n.dvdSubtitle
        case .dvbsub:
            L10n.dvbSubtitle
        case .jacosub:
            L10n.jacosub
        case .libzvbi_teletextdec:
            L10n.dvbTeletext
        case .mov_text:
            L10n.mpeg4TimedText
        case .mpl2:
            L10n.mpl2
        case .pjs:
            L10n.phoenixSubtitle
        case .pgssub:
            L10n.pgsSubtitle
        case .realtext:
            L10n.realText
        case .sami:
            L10n.smi
        case .ssa:
            L10n.ssa
        case .subrip:
            L10n.srt
        case .subviewer:
            L10n.subViewer
        case .subviewer1:
            L10n.subViewer1
        case .text:
            L10n.txt
        case .ttml:
            L10n.ttml
        case .vplayer:
            L10n.vPlayer
        case .vtt:
            L10n.webVTT
        case .xsub:
            L10n.xsub
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
