//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension VideoPlayerType {

    // MARK: direct play

    @ArrayBuilder<DirectPlayProfile>
    static var _nativeDirectPlayProfiles: [DirectPlayProfile] {
        DirectPlayProfile(type: .video) {
            AudioCodec.eac3 // Dolby Digital Plus (supports Atmos)
            AudioCodec.flac // FLAC lossless (smaller size)
            AudioCodec.alac // Apple Lossless
            AudioCodec.aac // AAC-LC lossy
            AudioCodec.ac3 // Dolby Digital lossy
        } videoCodecs: {
            VideoCodec.hevc // H.265/HEVC (prioritized)
            VideoCodec.h264 // H.264/AVC (HLS spec requirement)
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.mp4
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.alac // Apple Lossless (prioritized)
            AudioCodec.aac // AAC-LC
            AudioCodec.ac3 // Dolby Digital
        } videoCodecs: {
            VideoCodec.h264 // H.264/AVC
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.m4v
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.eac3 // Dolby Digital Plus (supports Atmos)
            AudioCodec.alac // Apple Lossless
            AudioCodec.pcm_s16le // PCM 16-bit LE (lossless)
            AudioCodec.pcm_s16be // PCM 16-bit BE (lossless)
            AudioCodec.pcm_s24le // PCM 24-bit LE (lossless)
            AudioCodec.pcm_s24be // PCM 24-bit BE (lossless)
            AudioCodec.aac // AAC-LC lossy
            AudioCodec.ac3 // Dolby Digital lossy
            AudioCodec.mp3 // MP3 lossy
        } videoCodecs: {
            VideoCodec.hevc // H.265/HEVC (prioritized)
            VideoCodec.h264 // H.264/AVC
            VideoCodec.mjpeg // Motion JPEG
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.mov
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.eac3 // Dolby Digital Plus (supports Atmos)
            AudioCodec.aac // AAC-LC
            AudioCodec.ac3 // Dolby Digital
            AudioCodec.mp3 // MP3
        } videoCodecs: {
            VideoCodec.h264 // H.264/AVC (MPEGTS only supports H.264 per HLS spec)
        } containers: {
            MediaContainer.mpegts
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.aac // AAC-LC
            AudioCodec.amr_nb // AMR-NB
        } videoCodecs: {
            VideoCodec.h264 // H.264/AVC
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.threeG2
            MediaContainer.threeGP
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.pcm_s16le // PCM 16-bit LE (lossless, prioritized)
            AudioCodec.pcm_mulaw // PCM mu-law
        } videoCodecs: {
            VideoCodec.mjpeg // Motion JPEG
        } containers: {
            MediaContainer.avi
        }
    }

    // MARK: transcoding

    @ArrayBuilder<TranscodingProfile>
    static var _nativeTranscodingProfiles: [TranscodingProfile] {
        TranscodingProfile(
            isBreakOnNonKeyFrames: true,
            context: .streaming,
            enableSubtitlesInManifest: true,
            maxAudioChannels: "8",
            minSegments: 2,
            protocol: MediaStreamProtocol.hls,
            type: .video
        ) {
            AudioCodec.flac // FLAC lossless (smaller)
            AudioCodec.alac // Apple Lossless (prioritized for transcoding)
            AudioCodec.eac3 // Dolby Digital Plus (supports up to 7.1, more efficient than AC3)
            AudioCodec.aac // AAC-LC lossy
            AudioCodec.ac3 // Dolby Digital lossy (5.1 max)
        } videoCodecs: {
            VideoCodec.hevc // H.265/HEVC (prioritized)
            VideoCodec.h264 // H.264/AVC
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.mp4
        }
    }

    // MARK: subtitle

    @ArrayBuilder<SubtitleProfile>
    static var _nativeSubtitleProfiles: [SubtitleProfile] {
        SubtitleProfile.build(method: .embed) {
            SubtitleFormat.cc_dec
            SubtitleFormat.ttml
        }

        SubtitleProfile.build(method: .encode) {
            SubtitleFormat.dvbsub
            SubtitleFormat.dvdsub
            SubtitleFormat.pgssub
            SubtitleFormat.xsub
        }

        SubtitleProfile.build(method: .hls) {
            SubtitleFormat.vtt
        }
    }
}
