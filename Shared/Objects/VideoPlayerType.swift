//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

enum VideoPlayerType: String, CaseIterable, Defaults.Serializable, Displayable {
    case native
    case swiftfin

    var displayTitle: String {
        switch self {
        case .native:
            return "Native"
        case .swiftfin:
            return "Swiftfin"
        }
    }

    var directPlayProfiles: [DirectPlayProfile] {
        switch self {
        case .native:
            return [
                // Apple limitation: no mp3 in mp4; avi only supports mjpeg with pcm
                // Right now, mp4 restrictions can't be enforced because
                // mp4, m4v, mov, 3gp,3g2 treated the same
                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.aac,
                        AudioCodec.ac3,
                        AudioCodec.alac,
                        AudioCodec.eac3,
                        AudioCodec.flac,
                        AudioCodec.opus,
                    ].map(\.rawValue).joined(separator: ","),
                    container: MediaContainer.mp4.rawValue,
                    type: .video,
                    videoCodec: [
                        VideoCodec.h264,
                        VideoCodec.hevc,
                        VideoCodec.mpeg4,
                    ].map(\.rawValue).joined(separator: ",")
                ),

                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.aac,
                        AudioCodec.ac3,
                        AudioCodec.alac,
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
                        AudioCodec.aac,
                        AudioCodec.ac3,
                        AudioCodec.alac,
                        AudioCodec.eac3,
                        AudioCodec.mp3,
                        AudioCodec.pcm_s16be,
                        AudioCodec.pcm_s16le,
                        AudioCodec.pcm_s24be,
                        AudioCodec.pcm_s24le,
                    ].map(\.rawValue).joined(separator: ","),
                    container: MediaContainer.mov.rawValue,
                    type: .video,
                    videoCodec: [
                        VideoCodec.h264,
                        VideoCodec.hevc,
                        VideoCodec.mjpeg,
                        VideoCodec.mpeg4,
                    ].map(\.rawValue).joined(separator: ",")
                ),

                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.aac,
                        AudioCodec.ac3,
                        AudioCodec.eac3,
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
                        MediaContainer.threeG2,
                        MediaContainer.threeGP,
                    ].map(\.rawValue).joined(separator: ","),
                    type: .video,
                    videoCodec: [
                        VideoCodec.h264,
                        VideoCodec.mpeg4,
                    ].map(\.rawValue).joined(separator: ",")
                ),

                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.pcm_mulaw,
                        AudioCodec.pcm_s16le,
                    ].map(\.rawValue).joined(separator: ","),
                    container: MediaContainer.avi.rawValue,
                    type: .video,
                    videoCodec: [
                        VideoCodec.mjpeg,
                    ].map(\.rawValue).joined(separator: ",")
                ),
            ]
        case .swiftfin:
            return [
                // Just make one profile because if VLCKit can't decode it in a certain container,
                // ffmpeg probably can't decode it for transcode either
                // No need to list containers or videocodecs since if jellyfin server can detect it/ffmpeg can decode it, so can VLCKit
                // However, list audiocodecs because ffmpeg can decode TrueHD/mlp but VLCKit cannot
                // This should result in the following string:
                // "aac,ac3,alac,amr_nb,amr_wb,dts,eac3,flac,mp1,mp2,mp3,nellymoser,opus,
                // pcm_alaw,pcm_bluray,pcm_dvd,pcm_mulaw,pcm_s16be,pcm_s16le,pcm_s24be,
                // pcm_s24le,pcm_u8,speex,vobis,wavpack,wmalossless,wmapro,wmav1,wmav2"
                DirectPlayProfile(
                    audioCodec: [
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
                    type: .video
                ),
            ]
        }
    }

    var transcodingProfiles: [TranscodingProfile] {
        switch self {
        case .native:
            return [
                TranscodingProfile(
                    audioCodec: [
                        AudioCodec.aac,
                        AudioCodec.ac3,
                        AudioCodec.alac,
                        AudioCodec.eac3,
                        AudioCodec.flac,
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
                        VideoCodec.h264,
                        VideoCodec.hevc,
                        VideoCodec.mpeg4,
                    ].map(\.rawValue).joined(separator: ",")
                ),
            ]
        case .swiftfin:
            return [
                // Build transcoding profiles
                // The only cases where transcoding should occur:
                // 1) TrueHD/mlp audio
                // 2) When server forces transcode for bitrate reasons
                // MP4 Audio Restrictions: pcm,wavpack,wmav2,wmav1,wmapro,wmalossless,nellymoser,speex,amr_nb,amr_wb in mp4
                // MP4 Video Restrictions: vp8,msmpeg4v3,msmpeg4v2,msmpeg4v1,theora,ffv1,flv1,wmv3,wmv2,wmv1
                TranscodingProfile(
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
                        VideoCodec.av1,
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
        }
    }

    var subtitleProfiles: [SubtitleProfile] {
        switch self {
        case .native:
            return [
                SubtitleFormat.cc_dec,
                SubtitleFormat.ttml,
            ].compactMap { $0.profiles[.embed] }
                +
                [
                    SubtitleFormat.dvbsub,
                    SubtitleFormat.dvdsub,
                    SubtitleFormat.pgssub,
                    SubtitleFormat.xsub,
                ].compactMap { $0.profiles[.encode] }
                +
                [
                    SubtitleFormat.vtt,
                ].compactMap { $0.profiles[.hls] }
        case .swiftfin:
            return [
                SubtitleFormat.ass,
                SubtitleFormat.cc_dec,
                SubtitleFormat.dvbsub,
                SubtitleFormat.dvdsub,
                SubtitleFormat.jacosub,
                SubtitleFormat.libzvbi_teletextdec,
                SubtitleFormat.mov_text,
                SubtitleFormat.mpl2,
                SubtitleFormat.pgssub,
                SubtitleFormat.pjs,
                SubtitleFormat.realtext,
                SubtitleFormat.sami,
                SubtitleFormat.ssa,
                SubtitleFormat.subrip,
                SubtitleFormat.subviewer,
                SubtitleFormat.subviewer1,
                SubtitleFormat.text,
                SubtitleFormat.ttml,
                SubtitleFormat.vplayer,
                SubtitleFormat.vtt,
                SubtitleFormat.xsub,
            ].compactMap { $0.profiles[.embed] }
                +
                [
                    SubtitleFormat.ass,
                    SubtitleFormat.dvbsub,
                    SubtitleFormat.dvdsub,
                    SubtitleFormat.jacosub,
                    SubtitleFormat.libzvbi_teletextdec,
                    SubtitleFormat.mpl2,
                    SubtitleFormat.pgssub,
                    SubtitleFormat.pjs,
                    SubtitleFormat.realtext,
                    SubtitleFormat.sami,
                    SubtitleFormat.ssa,
                    SubtitleFormat.subrip,
                    SubtitleFormat.subviewer,
                    SubtitleFormat.subviewer1,
                    SubtitleFormat.text,
                    SubtitleFormat.ttml,
                    SubtitleFormat.vplayer,
                    SubtitleFormat.vtt,
                    SubtitleFormat.xsub,
                ].compactMap { $0.profiles[.external] }
        }
    }

    var codecProfiles: [CodecProfile] {
        [
            CodecProfile(
                applyConditions: h264CodecConditions,
                codec: VideoCodec.h264.rawValue,
                type: .video
            ),
            CodecProfile(
                applyConditions: h265CodecConditions,
                codec: VideoCodec.hevc.rawValue,
                type: .video
            ),
        ]
    }

    var h264CodecConditions: [ProfileCondition] {
        [
            ProfileCondition(
                condition: .notEquals,
                isRequired: false,
                property: .isAnamorphic,
                value: "true"
            ),

            ProfileCondition(
                condition: .equalsAny,
                isRequired: false,
                property: .videoProfile,
                value: "high|main|baseline|constrained baseline"
            ),

            ProfileCondition(
                condition: .lessThanEqual,
                isRequired: false,
                property: .videoLevel,
                value: "80"
            ),

            ProfileCondition(
                condition: .notEquals,
                isRequired: false,
                property: .isInterlaced,
                value: "true"
            ),
        ]
    }

    var h265CodecConditions: [ProfileCondition] {
        [
            ProfileCondition(
                condition: .notEquals,
                isRequired: false,
                property: .isAnamorphic,
                value: "true"
            ),

            ProfileCondition(
                condition: .equalsAny,
                isRequired: false,
                property: .videoProfile,
                value: "high|main|main 10"
            ),

            ProfileCondition(
                condition: .lessThanEqual,
                isRequired: false,
                property: .videoLevel,
                value: "175"
            ),

            ProfileCondition(
                condition: .notEquals,
                isRequired: false,
                property: .isInterlaced,
                value: "true"
            ),
        ]
    }

    var responseProfiles: [ResponseProfile] {
        [
            ResponseProfile(
                container: MediaContainer.m4v.rawValue,
                mimeType: "video/mp4",
                type: .video
            ),
        ]
    }
}
