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
            return "AAC"
        case .ac3:
            return "AC-3"
        case .amr_nb:
            return "AMR-NB"
        case .amr_wb:
            return "AMR-WB"
        case .dts:
            return "DTS"
        case .dts_hd:
            return "DTS-HD"
        case .eac3:
            return "E-AC-3"
        case .flac:
            return "FLAC"
        case .alac:
            return "ALAC"
        case .mlp:
            return "MLP"
        case .mp1:
            return "MP1"
        case .mp2:
            return "MP2"
        case .mp3:
            return "MP3"
        case .nellymoser:
            return "Nellymoser"
        case .opus:
            return "Opus"
        case .pcm_alaw:
            return "PCM ALAW"
        case .pcm_bluray:
            return "PCM Bluray"
        case .pcm_dvd:
            return "PCM DVD"
        case .pcm_mulaw:
            return "PCM MULAW"
        case .pcm_s16be:
            return "PCM S16BE"
        case .pcm_s16le:
            return "PCM S16LE"
        case .pcm_s24be:
            return "PCM S24BE"
        case .pcm_s24le:
            return "PCM S24LE"
        case .pcm_u8:
            return "PCM U8"
        case .speex:
            return "Speex"
        case .truehd:
            return "TrueHD"
        case .vorbis:
            return "Vorbis"
        case .wavpack:
            return "WavPack"
        case .wmalossless:
            return "WMA Lossless"
        case .wmapro:
            return "WMA Pro"
        case .wmav1:
            return "WMA V1"
        case .wmav2:
            return "WMA V2"
        }
    }
}
