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

        // Build direct play profiles
        profile.directPlayProfiles = [
            // Apple limitation: no mp3 in mp4; avi only supports mjpeg with pcm
            // Right now, mp4 restrictions can't be enforced because mp4, m4v, mov, 3gp,3g2 treated the same
            DirectPlayProfile(
                audioCodec: "flac,alac,aac,eac3,ac3,opus",
                container: "mp4",
                type: .video,
                videoCodec: "hevc,h264,mpeg4"
            ),
            DirectPlayProfile(
                audioCodec: "alac,aac,ac3",
                container: "m4v",
                type: .video,
                videoCodec: "h264,mpeg4"
            ),
            DirectPlayProfile(
                audioCodec: "alac,aac,eac3,ac3,mp3,pcm_s24be,pcm_s24le,pcm_s16be,pcm_s16le",
                container: "mov",
                type: .video,
                videoCodec: "hevc,h264,mpeg4,mjpeg"
            ),
            DirectPlayProfile(
                audioCodec: "aac,eac3,ac3,mp3",
                container: "mpegts",
                type: .video,
                videoCodec: "h264"
            ),
            DirectPlayProfile(
                audioCodec: "aac,amr_nb",
                container: "3gp,3g2",
                type: .video,
                videoCodec: "h264,mpeg4"
            ),
            DirectPlayProfile(
                audioCodec: "pcm_s16le,pcm_mulaw",
                container: "avi",
                type: .video,
                videoCodec: "mjpeg"
            ),
        ]

        // Build transcoding profiles
        profile.transcodingProfiles = [
            TranscodingProfile(
                audioCodec: "flac,alac,aac,eac3,ac3,opus",
                isBreakOnNonKeyFrames: true,
                container: "mp4",
                context: .streaming,
                maxAudioChannels: "8",
                minSegments: 2,
                protocol: "hls",
                type: .video,
                videoCodec: "hevc,h264,mpeg4"
            ),
        ]

        // Create subtitle profiles
        profile.subtitleProfiles = [
            // FFmpeg can only convert bitmap to bitmap and text to text; burn in bitmap subs
            SubtitleProfile(format: "pgssub", method: .encode),
            SubtitleProfile(format: "dvdsub", method: .encode),
            SubtitleProfile(format: "dvbsub", method: .encode),
            SubtitleProfile(format: "xsub", method: .encode),
            // According to Apple HLS authoring specs, WebVTT must be in a text file delivered via HLS
            SubtitleProfile(format: "vtt", method: .hls), // webvtt
            // Apple HLS authoring spec has closed captions in video segments and TTML in fmp4
            SubtitleProfile(format: "ttml", method: .embed),
            SubtitleProfile(format: "cc_dec", method: .embed),
        ]

        return profile
    }
}
