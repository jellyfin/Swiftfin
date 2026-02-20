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
            "AAC"
        case .ac3:
            "AC-3"
        case .amr_nb:
            "AMR-NB"
        case .amr_wb:
            "AMR-WB"
        case .dts:
            "DTS"
        case .dts_hd:
            "DTS-HD"
        case .eac3:
            "E-AC-3"
        case .flac:
            "FLAC"
        case .alac:
            "ALAC"
        case .mlp:
            "MLP"
        case .mp1:
            "MP1"
        case .mp2:
            "MP2"
        case .mp3:
            "MP3"
        case .nellymoser:
            "Nellymoser"
        case .opus:
            "Opus"
        case .pcm_alaw:
            "PCM ALAW"
        case .pcm_bluray:
            "PCM Bluray"
        case .pcm_dvd:
            "PCM DVD"
        case .pcm_mulaw:
            "PCM MULAW"
        case .pcm_s16be:
            "PCM S16BE"
        case .pcm_s16le:
            "PCM S16LE"
        case .pcm_s24be:
            "PCM S24BE"
        case .pcm_s24le:
            "PCM S24LE"
        case .pcm_u8:
            "PCM U8"
        case .speex:
            "Speex"
        case .truehd:
            "TrueHD"
        case .vorbis:
            "Vorbis"
        case .wavpack:
            "WavPack"
        case .wmalossless:
            "WMA Lossless"
        case .wmapro:
            "WMA Pro"
        case .wmav1:
            "WMA V1"
        case .wmav2:
            "WMA V2"
        }
    }
}
