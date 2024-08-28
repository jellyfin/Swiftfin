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
import SwiftUI

struct VideoPlayerType: Codable, Defaults.Serializable, Equatable {
    let displayTitle: String
    let directPlayProfiles: [DirectPlayProfile]
    let transcodingProfiles: [TranscodingProfile]
    let subtitleProfiles: [SubtitleProfile]
    let codecProfiles: [CodecProfile]
    let responseProfiles: [ResponseProfile]

    // MARK: - Player Types

    static var native: VideoPlayerType {
        makeNativeVideoPlayerProfile()
    }

    static var swiftfin: VideoPlayerType {
        makeSwiftfinVideoPlayerProfile()
    }

    // MARK: - Native Device Profile

    private static func makeNativeVideoPlayerProfile() -> VideoPlayerType {
        VideoPlayerType(
            displayTitle: L10n.nativePlayer,
            directPlayProfiles: [
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
            ],
            transcodingProfiles: [
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
            ],
            subtitleProfiles: [
                SubtitleFormat.cc_dec,
                SubtitleFormat.ttml,
            ].compactMap { $0.profiles[.embed] }
                + [
                    SubtitleFormat.dvbsub,
                    SubtitleFormat.dvdsub,
                    SubtitleFormat.pgssub,
                    SubtitleFormat.xsub,
                ].compactMap { $0.profiles[.encode] }
                + [
                    SubtitleFormat.vtt,
                ].compactMap { $0.profiles[.hls] },
            codecProfiles: self.sharedCodecProfiles(),
            responseProfiles: self.sharedResponseProfiles()
        )
    }

    // MARK: - Swiftfin Device Profile

    private static func makeSwiftfinVideoPlayerProfile() -> VideoPlayerType {
        VideoPlayerType(
            displayTitle: "Swiftfin",
            directPlayProfiles: [
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
            ],
            transcodingProfiles: [
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
            ],
            subtitleProfiles: [
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
                + [
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
                ].compactMap { $0.profiles[.external] },
            codecProfiles: self.sharedCodecProfiles(),
            responseProfiles: self.sharedResponseProfiles()
        )
    }

    // MARK: - Shared Codec Profiles

    private static func sharedCodecProfiles() -> [CodecProfile] {
        [
            CodecProfile(
                applyConditions: [
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
                ],
                codec: VideoCodec.h264.rawValue,
                type: .video
            ),
            CodecProfile(
                applyConditions: [
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
                ],
                codec: VideoCodec.hevc.rawValue,
                type: .video
            ),
        ]
    }

    // MARK: - Shared Repsonse Profiles

    private static func sharedResponseProfiles() -> [ResponseProfile] {
        [
            ResponseProfile(
                container: MediaContainer.m4v.rawValue,
                mimeType: "video/mp4",
                type: .video
            ),
        ]
    }
}
