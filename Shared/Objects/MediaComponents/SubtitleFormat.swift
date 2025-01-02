//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

enum SubtitleFormat: String, CaseIterable, Codable, Displayable, Defaults.Serializable {

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
}
