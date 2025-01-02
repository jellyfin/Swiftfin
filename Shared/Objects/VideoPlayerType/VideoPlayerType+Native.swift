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
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
            AudioCodec.eac3
            AudioCodec.flac
        } videoCodecs: {
            VideoCodec.h261
            VideoCodec.hevc
            VideoCodec.mpeg4
        } containers: {
            MediaContainer.mp4
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
        } videoCodecs: {
            VideoCodec.h264
            VideoCodec.mpeg4
        } containers: {
            MediaContainer.m4v
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
            AudioCodec.eac3
            AudioCodec.mp3
            AudioCodec.pcm_s16be
            AudioCodec.pcm_s16le
            AudioCodec.pcm_s24be
            AudioCodec.pcm_s24le
        } videoCodecs: {
            VideoCodec.h264
            VideoCodec.hevc
            VideoCodec.mjpeg
            VideoCodec.mpeg4
        } containers: {
            MediaContainer.mov
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.eac3
            AudioCodec.mp3
        } videoCodecs: {
            VideoCodec.h264
        } containers: {
            MediaContainer.mpegts
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.aac
            AudioCodec.amr_nb
        } videoCodecs: {
            VideoCodec.h264
            VideoCodec.mpeg4
        } containers: {
            MediaContainer.threeG2
            MediaContainer.threeGP
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.pcm_mulaw
            AudioCodec.pcm_s16le
        } videoCodecs: {
            VideoCodec.mjpeg
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
            protocol: "hls",
            type: .video
        ) {
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
            AudioCodec.eac3
            AudioCodec.flac
        } videoCodecs: {
            VideoCodec.h264
            VideoCodec.hevc
            VideoCodec.mpeg4
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
