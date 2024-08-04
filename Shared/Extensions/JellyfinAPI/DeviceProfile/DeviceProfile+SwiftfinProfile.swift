//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension DeviceProfile {
    static func swiftfinProfile() -> DeviceProfile {
        var profile: DeviceProfile = .init()

        // Build direct play profiles
        // No need to list containers or videocodecs since if jellyfin server can detect it/ffmpeg can decode it, so can
        // VLCKit
        // However, list audiocodecs because ffmpeg can decode TrueHD/mlp but VLCKit cannot
        // ---
        // Results in the following String:
        // "aac,ac3,alac,amr_nb,amr_wb,apc3,dts,eac3,flac,mp1,mp2,mp3,nellymoser,opus,pcm_alaw,pcm_bluray,pcm_dvd,pcm_mulaw,pcm_s16be,pcm_s16le,pcm_s24be,pcm_s24le,pcm_u8,speex,vorbis,wavpack,wmalossless,wmapro,wmav1,wmav2"
        profile.directPlayProfiles = [
            DirectPlayProfile(
                audioCodec:
                [
                    AudioCodec.aac,
                    AudioCodec.ac3,
                    AudioCodec.alac,
                    AudioCodec.amr_nb,
                    AudioCodec.amr_wb,
                    AudioCodec.dts,
                    AudioCodec.eac3,
                    AudioCodec.flac,
                    AudioCodec.mp1,
                    AudioCodec.mp2,
                    AudioCodec.mp3,
                    AudioCodec.nellymoser,
                    AudioCodec.opus,
                    AudioCodec.pcm_alaw,
                    AudioCodec.pcm_bluray,
                    AudioCodec.pcm_dvd,
                    AudioCodec.pcm_mulaw,
                    AudioCodec.pcm_s16be,
                    AudioCodec.pcm_s16le,
                    AudioCodec.pcm_s24be,
                    AudioCodec.pcm_s24le,
                    AudioCodec.pcm_u8,
                    AudioCodec.speex,
                    AudioCodec.vorbis,
                    AudioCodec.wavpack,
                    AudioCodec.wmalossless,
                    AudioCodec.wmapro,
                    AudioCodec.wmav1,
                    AudioCodec.wmav2,
                ].map(\.rawValue).joined(separator: ","),
                type: .video,

                videoCodec: [
                    VideoCodec.h263,
                    VideoCodec.h264,
                    VideoCodec.hevc,
                    VideoCodec.mjpeg,
                    VideoCodec.mpeg1video,
                    VideoCodec.mpeg2video,
                    VideoCodec.mpeg4,
                    VideoCodec.vc1,
                    VideoCodec.vp9,
                ].map(\.rawValue).joined(separator: ",")
            ),
        ]

        // Build transcoding profiles
        // The only cases where transcoding should occur:
        // 1) TrueHD/mlp audio
        // 2) When server forces transcode for bitrate reasons
        // ---
        // Results in the following Strings:
        // "aac,ac3,alac,dts,eac3,flac,mp1,mp2,mp3,opus,vorbis"
        // "av1,h263,h264,hevc,mjpeg,mpeg1video,mpeg2video,mpeg4,vc1,vp9"*
        // *av1 removed.
        // ---
        // Not in MP4:
        // PCM,wavpack,wmav2,wmav1,wmapro,wmalossless,nellymoser,speex,amr_nb,amr_wb
        // vp8,msmpeg4v3,msmpeg4v2,msmpeg4v1,theora,ffv1,flv1,wmv3,wmv2,wmv1
        profile.transcodingProfiles = [TranscodingProfile(
            audioCodec: [
                AudioCodec.aac,
                AudioCodec.ac3,
                AudioCodec.alac,
                AudioCodec.dts,
                AudioCodec.eac3,
                AudioCodec.flac,
                AudioCodec.mp1,
                AudioCodec.mp2,
                AudioCodec.mp3,
                AudioCodec.opus,
                AudioCodec.vorbis,
            ].map(\.rawValue).joined(separator: ","),
            isBreakOnNonKeyFrames: true,
            container: MediaContainer.mp4.rawValue,
            context: .streaming,
            maxAudioChannels: "8",
            minSegments: 2,
            protocol: StreamType.hls.rawValue,
            type: .video,
            videoCodec: [
                // VideoCodec.av1, Rmoving AV1 since iPhone <13 cannot do this natively
                VideoCodec.h263,
                VideoCodec.h264,
                VideoCodec.hevc,
                VideoCodec.mjpeg,
                VideoCodec.mpeg1video,
                VideoCodec.mpeg2video,
                VideoCodec.mpeg4,
                VideoCodec.vc1,
                VideoCodec.vp9,
            ].map(\.rawValue).joined(separator: ",")
        )]

        // Create subtitle profiles
        profile.subtitleProfiles = [
            // Embedded profiles
            SubtitleFormat.pgssub,
            SubtitleFormat.dvdsub,
            SubtitleFormat.subrip,
            SubtitleFormat.ass,
            SubtitleFormat.ssa,
            SubtitleFormat.vtt,
            SubtitleFormat.mov_text,
            SubtitleFormat.ttml,
            SubtitleFormat.text,
            SubtitleFormat.dvbsub,
            SubtitleFormat.libzvbi_teletextdec,
            SubtitleFormat.xsub,
            SubtitleFormat.vplayer,
            SubtitleFormat.subviewer,
            SubtitleFormat.subviewer1,
            SubtitleFormat.sami,
            SubtitleFormat.realtext,
            SubtitleFormat.pjs,
            SubtitleFormat.mpl2,
            SubtitleFormat.jacosub,
            SubtitleFormat.cc_dec,
        ].compactMap { $0.profiles[.embed] } +

            [
                // External profiles
                SubtitleFormat.pgssub,
                SubtitleFormat.dvdsub,
                SubtitleFormat.subrip,
                SubtitleFormat.ass,
                SubtitleFormat.ssa,
                SubtitleFormat.vtt,
                SubtitleFormat.mov_text,
                SubtitleFormat.ttml,
                SubtitleFormat.text,
                SubtitleFormat.dvbsub,
                SubtitleFormat.libzvbi_teletextdec,
                SubtitleFormat.xsub,
                SubtitleFormat.vplayer,
                SubtitleFormat.subviewer,
                SubtitleFormat.subviewer1,
                SubtitleFormat.sami,
                SubtitleFormat.realtext,
                SubtitleFormat.pjs,
                SubtitleFormat.mpl2,
                SubtitleFormat.jacosub,
                SubtitleFormat.cc_dec,
            ].compactMap { $0.profiles[.external] }

        return profile
    }
}
