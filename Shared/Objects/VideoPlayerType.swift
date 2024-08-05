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
                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.flac,
                        AudioCodec.alac,
                        AudioCodec.aac,
                        AudioCodec.eac3,
                        AudioCodec.ac3,
                        AudioCodec.opus,
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
                    container: MediaContainer.mp4.rawValue,
                    type: .video,
                    videoCodec: [
                        VideoCodec.hevc,
                        VideoCodec.h264,
                        VideoCodec.mpeg4,
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
                ),

                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.alac,
                        AudioCodec.aac,
                        AudioCodec.ac3,
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
                    container: MediaContainer.m4v.rawValue,
                    type: .video,
                    videoCodec: [
                        VideoCodec.h264,
                        VideoCodec.mpeg4,
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
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
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
                    container: MediaContainer.mov.rawValue,
                    type: .video,
                    videoCodec: [
                        VideoCodec.hevc,
                        VideoCodec.h264,
                        VideoCodec.mpeg4,
                        VideoCodec.mjpeg,
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
                ),

                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.aac,
                        AudioCodec.eac3,
                        AudioCodec.ac3,
                        AudioCodec.mp3,
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
                    container: MediaContainer.mpegts.rawValue,
                    type: .video,
                    videoCodec: [
                        VideoCodec.h264,
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
                ),

                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.aac,
                        AudioCodec.amr_nb,
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
                    container: [
                        MediaContainer.threeGP,
                        MediaContainer.threeG2,
                    ].map(\.rawValue).joined(separator: ","),
                    type: .video,
                    videoCodec: [
                        VideoCodec.h264,
                        VideoCodec.mpeg4,
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
                ),

                DirectPlayProfile(
                    audioCodec: [
                        AudioCodec.pcm_s16le,
                        AudioCodec.pcm_mulaw,
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
                    container: MediaContainer.avi.rawValue,
                    type: .video,
                    videoCodec: [
                        VideoCodec.mjpeg,
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
                ),
            ]
        case .swiftfin:
            return [
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
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
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
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
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
                        AudioCodec.flac,
                        AudioCodec.alac,
                        AudioCodec.aac,
                        AudioCodec.eac3,
                        AudioCodec.ac3,
                        AudioCodec.opus,
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
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
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
                ),
            ]
        case .swiftfin:
            return [
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
                    ].filter {
                        AudioCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ","),
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
                    ].filter {
                        VideoCodec.decodableCodecs().contains($0)
                    }.map(\.rawValue).joined(separator: ",")
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
            ].compactMap { $0.profiles[.embed] }
                +
                [
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
        }
    }

    var codecProfiles: [CodecProfile] {
        [
            CodecProfile(
                applyConditions: self.h264CodecConditions,
                codec: VideoCodec.h264.rawValue,
                type: .video
            ),
            CodecProfile(
                applyConditions: self.h265CodecConditions,
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
