//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension DeviceProfile {
    static func nativeProfile() -> DeviceProfile {
        var profile: DeviceProfile = .init()

        // Build DirectPlay profiles
        profile.directPlayProfiles = [

            DirectPlayProfile(
                audioCodec: [
                    AudioCodec.flac,
                    AudioCodec.alac,
                    AudioCodec.aac,
                    AudioCodec.eac3,
                    AudioCodec.ac3,
                    AudioCodec.opus,
                ].map(\.rawValue).joined(separator: ","),
                container: MediaContainer.mp4.rawValue,
                type: .video,
                videoCodec: [
                    VideoCodec.hevc,
                    VideoCodec.h264,
                    VideoCodec.mpeg4,
                ].map(\.rawValue).joined(separator: ",")
            ),

            DirectPlayProfile(
                audioCodec: [
                    AudioCodec.alac,
                    AudioCodec.aac,
                    AudioCodec.ac3,
                ].map(\.rawValue).joined(separator: ","),
                container: MediaContainer.m4v.rawValue,
                type: .video,
                videoCodec: [
                    VideoCodec.h264,
                    VideoCodec.mpeg4,
                ].map(\.rawValue).joined(separator: ",")
            ),

            DirectPlayProfile(
                audioCodec: [
                    AudioCodec.alac,
                    AudioCodec.aac,
                    AudioCodec.eac3,
                    AudioCodec.ac3,
                    AudioCodec.mp3,
                    AudioCodec.pcm_s24be,
                    AudioCodec.pcm_s24le,
                    AudioCodec.pcm_s16be,
                    AudioCodec.pcm_s16le,
                ].map(\.rawValue).joined(separator: ","),
                container: MediaContainer.mov.rawValue,
                type: .video,
                videoCodec: [
                    VideoCodec.hevc,
                    VideoCodec.h264,
                    VideoCodec.mpeg4,
                    VideoCodec.mjpeg,
                ].map(\.rawValue).joined(separator: ",")
            ),

            DirectPlayProfile(
                audioCodec: [
                    AudioCodec.aac,
                    AudioCodec.eac3,
                    AudioCodec.ac3,
                    AudioCodec.mp3,
                ].map(\.rawValue).joined(separator: ","),
                container: MediaContainer.mpegts.rawValue,
                type: .video,
                videoCodec: [
                    VideoCodec.h264,
                ].map(\.rawValue).joined(separator: ",")
            ),

            DirectPlayProfile(
                audioCodec: [
                    AudioCodec.aac,
                    AudioCodec.amr_nb,
                ].map(\.rawValue).joined(separator: ","),
                container: [
                    MediaContainer.threeGP,
                    MediaContainer.threeG2,
                ].map(\.rawValue).joined(separator: ","),
                type: .video,
                videoCodec: [
                    VideoCodec.h264,
                    VideoCodec.mpeg4,
                ].map(\.rawValue).joined(separator: ",")
            ),

            DirectPlayProfile(
                audioCodec: [
                    AudioCodec.pcm_s16le,
                    AudioCodec.pcm_mulaw,
                ].map(\.rawValue).joined(separator: ","),
                container: MediaContainer.avi.rawValue,
                type: .video,
                videoCodec: [
                    VideoCodec.mjpeg,
                ].map(\.rawValue).joined(separator: ",")
            ),
        ]

        // Build Transcoding profiles
        profile.transcodingProfiles = [
            TranscodingProfile(
                audioCodec: [
                    AudioCodec.flac,
                    AudioCodec.alac,
                    AudioCodec.aac,
                    AudioCodec.eac3,
                    AudioCodec.ac3,
                    AudioCodec.opus,
                ].map(\.rawValue).joined(separator: ","),
                isBreakOnNonKeyFrames: true,
                container: MediaContainer.mp4.rawValue,
                context: .streaming,
                maxAudioChannels: "8",
                minSegments: 2,
                protocol: StreamType.hls.rawValue,
                type: .video,
                videoCodec: [
                    VideoCodec.hevc,
                    VideoCodec.h264,
                    VideoCodec.mpeg4,
                ].map(\.rawValue).joined(separator: ",")
            ),
        ]

        // Build Subtitle profiles
        profile.subtitleProfiles = [
            // Embedded profiles
            SubtitleFormat.cc_dec,
            SubtitleFormat.ttml,
        ].compactMap { $0.profiles[.embed] } +

            [
                // Encode profiles
                SubtitleFormat.dvbsub,
                SubtitleFormat.dvdsub,
                SubtitleFormat.pgssub,
                SubtitleFormat.xsub,
            ].compactMap { $0.profiles[.encode] } +

            [
                // HLS profiles
                SubtitleFormat.vtt,
            ].compactMap { $0.profiles[.hls] }

        return profile
    }
}
