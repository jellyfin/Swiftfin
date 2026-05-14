//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum AudioCodec: String, CaseIterable, Codable, Displayable, Storable {

    case aac
    case ac3
    case amr_nb
    case amr_wb
    case dts
    case dts_hd
    case eac3
    case flac
    case alac
    case mlp
    case mp1
    case mp2
    case mp3
    case nellymoser
    case opus
    case pcm_alaw
    case pcm_bluray
    case pcm_dvd
    case pcm_mulaw
    case pcm_s16be
    case pcm_s16le
    case pcm_s24be
    case pcm_s24le
    case pcm_u8
    case speex
    case truehd
    case vorbis
    case wavpack
    case wmalossless
    case wmapro
    case wmav1
    case wmav2

    var displayTitle: String {
        switch self {
        case .aac:
            L10n.aac
        case .ac3:
            L10n.ac3
        case .amr_nb:
            L10n.amrNB
        case .amr_wb:
            L10n.amrWB
        case .dts:
            L10n.dts
        case .dts_hd:
            L10n.dtsHD
        case .eac3:
            L10n.eac3
        case .flac:
            L10n.flac
        case .alac:
            L10n.alac
        case .mlp:
            L10n.mlp
        case .mp1:
            L10n.mp1
        case .mp2:
            L10n.mp2
        case .mp3:
            L10n.mp3
        case .nellymoser:
            L10n.nellymoser
        case .opus:
            L10n.opus
        case .pcm_alaw:
            L10n.pcmALAW
        case .pcm_bluray:
            L10n.pcmBluray
        case .pcm_dvd:
            L10n.pcmDVD
        case .pcm_mulaw:
            L10n.pcmMULAW
        case .pcm_s16be:
            L10n.pcmS16BE
        case .pcm_s16le:
            L10n.pcmS16LE
        case .pcm_s24be:
            L10n.pcmS24BE
        case .pcm_s24le:
            L10n.pcmS24LE
        case .pcm_u8:
            L10n.pcmU8
        case .speex:
            L10n.speex
        case .truehd:
            L10n.trueHD
        case .vorbis:
            L10n.vorbis
        case .wavpack:
            L10n.wavPack
        case .wmalossless:
            L10n.wmaLossless
        case .wmapro:
            L10n.wmaPro
        case .wmav1:
            L10n.wmaV1
        case .wmav2:
            L10n.wmaV2
        }
    }
}
