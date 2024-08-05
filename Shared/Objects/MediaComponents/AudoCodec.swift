//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import AudioToolbox
import Defaults

enum AudioCodec: String, CaseIterable, Displayable, Defaults.Serializable {
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

    var audioFormatID: AudioFormatID? {
        switch self {
        case .aac:
            return kAudioFormatMPEG4AAC
        case .ac3:
            return kAudioFormatAC3
        case .amr_nb:
            return kAudioFormatAMR
        case .amr_wb:
            return kAudioFormatAMR_WB
        case .dts:
            return nil // kAudioFormatDTS
        case .dts_hd:
            return nil // kAudioFormatDTSHD
        case .eac3:
            return kAudioFormatEnhancedAC3
        case .flac:
            return kAudioFormatFLAC
        case .alac:
            return kAudioFormatAppleLossless
        case .mlp:
            return nil // No kAudioFormat constant available
        case .mp1:
            return kAudioFormatMPEGLayer1
        case .mp2:
            return kAudioFormatMPEGLayer2
        case .mp3:
            return kAudioFormatMPEGLayer3
        case .nellymoser:
            return nil // No kAudioFormat constant available
        case .opus:
            return nil // No kAudioFormat constant available
        case .pcm_alaw:
            return kAudioFormatALaw
        case .pcm_bluray:
            return nil // No kAudioFormat constant available
        case .pcm_dvd:
            return nil // No kAudioFormat constant available
        case .pcm_mulaw:
            return kAudioFormatULaw
        case .pcm_s16be, .pcm_s16le, .pcm_s24be, .pcm_s24le, .pcm_u8:
            return kAudioFormatLinearPCM
        case .speex:
            return nil // No kAudioFormat constant available
        case .truehd:
            return nil // No kAudioFormat constant available
        case .vorbis:
            return nil // No kAudioFormat constant available
        case .wavpack:
            return nil // No kAudioFormat constant available
        case .wmalossless:
            return nil // No kAudioFormat constant available
        case .wmapro:
            return nil // kAudioFormatWMA9Professional
        case .wmav1:
            return nil // kAudioFormatWindowsMediaAudioV1
        case .wmav2:
            return nil // kAudioFormatWindowsMediaAudioV2
        }
    }

    var isSupported: Bool {
        guard var formatID = self.audioFormatID else {
            return false
        }

        var size = UInt32(MemoryLayout<UInt32>.size)
        var numberOfDecoders: UInt32 = 0

        let status = AudioFormatGetPropertyInfo(
            kAudioFormatProperty_Decoders,
            UInt32(MemoryLayout.size(ofValue: formatID)),
            &formatID,
            &size
        )

        if status != noErr {
            print("AudioFormatGetPropertyInfo error for \(self.rawValue): \(status)")
            return false
        }

        numberOfDecoders = size / UInt32(MemoryLayout<AudioClassDescription>.size)

        return numberOfDecoders > 0
    }

    static func decodableCodecs() -> [AudioCodec] {
        AudioCodec.allCases.filter(\.isSupported)
    }
}
