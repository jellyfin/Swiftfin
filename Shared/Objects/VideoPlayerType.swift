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

struct VideoPlayerType: Codable, Equatable, Hashable, CaseIterable, Displayable, Defaults.Serializable {
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

    // MARK: - All Cases

    static var allCases: [VideoPlayerType] {
        [.native, .swiftfin]
    }

    // MARK: - Native Device Profile

    private static func makeNativeVideoPlayerProfile() -> VideoPlayerType {
        VideoPlayerType(
            displayTitle: "Native",
            directPlayProfiles: [

                DirectPlayProfile(
                    audioCodec: AudioCodec.unwrap(
                        [
                            .aac,
                            .ac3,
                            .alac,
                            .eac3,
                            .flac,
                            .opus,
                        ]
                    ),
                    container: MediaContainer.mp4.rawValue,
                    type: .video,
                    videoCodec: VideoCodec.unwrap(
                        [
                            .h264,
                            .hevc,
                            .mpeg4,
                        ]
                    )
                ),

                DirectPlayProfile(
                    audioCodec: AudioCodec.unwrap(
                        [
                            .aac,
                            .ac3,
                            .alac,
                        ]
                    ),
                    container: MediaContainer.m4v.rawValue,
                    type: .video,
                    videoCodec: VideoCodec.unwrap(
                        [
                            .h264,
                            .mpeg4,
                        ]
                    )
                ),

                DirectPlayProfile(
                    audioCodec: AudioCodec.unwrap(
                        [
                            .aac,
                            .ac3,
                            .alac,
                            .eac3,
                            .mp3,
                            .pcm_s16be,
                            .pcm_s16le,
                            .pcm_s24be,
                            .pcm_s24le,
                        ]
                    ),
                    container: MediaContainer.mov.rawValue,
                    type: .video,
                    videoCodec: VideoCodec.unwrap(
                        [
                            .h264,
                            .hevc,
                            .mjpeg,
                            .mpeg4,
                        ]
                    )
                ),

                DirectPlayProfile(
                    audioCodec: AudioCodec.unwrap(
                        [
                            .aac,
                            .ac3,
                            .eac3,
                            .mp3,
                        ]
                    ),
                    container: MediaContainer.mpegts.rawValue,
                    type: .video,
                    videoCodec: VideoCodec.h264.rawValue
                ),

                DirectPlayProfile(
                    audioCodec: AudioCodec.unwrap(
                        [
                            .aac,
                            .amr_nb,
                        ]
                    ),
                    container: MediaContainer.unwrap(
                        [
                            .threeG2,
                            .threeGP,
                        ]
                    ),
                    type: .video,
                    videoCodec: VideoCodec.unwrap(
                        [
                            .h264,
                            .mpeg4,
                        ]
                    )
                ),

                DirectPlayProfile(
                    audioCodec: AudioCodec.unwrap(
                        [
                            .pcm_mulaw,
                            .pcm_s16le,
                        ]
                    ),
                    container: MediaContainer.avi.rawValue,
                    type: .video,
                    videoCodec: VideoCodec.mjpeg.rawValue
                ),
            ],
            transcodingProfiles: [

                TranscodingProfile(
                    audioCodec: AudioCodec.unwrap(
                        [
                            .aac,
                            .ac3,
                            .alac,
                            .eac3,
                            .flac,
                            .opus,
                        ]
                    ),
                    isBreakOnNonKeyFrames: true,
                    container: MediaContainer.mp4.rawValue,
                    context: .streaming,
                    maxAudioChannels: "8",
                    minSegments: 2,
                    protocol: StreamType.hls.rawValue,
                    type: .video,
                    videoCodec: VideoCodec.unwrap(
                        [
                            .h264,
                            .hevc,
                            .mpeg4,
                        ]
                    )
                ),
            ],
            subtitleProfiles: {
                var subtitles = [SubtitleProfile]()

                subtitles.append(
                    contentsOf:
                    SubtitleFormat.unwrap(
                        subtitleDeliveryMethod: .embed,
                        [
                            .cc_dec,
                            .ttml,
                        ]
                    )
                )

                subtitles.append(
                    contentsOf:
                    SubtitleFormat.unwrap(
                        subtitleDeliveryMethod: .encode,
                        [
                            .dvbsub,
                            .dvdsub,
                            .pgssub,
                            .xsub,
                        ]
                    )
                )

                subtitles.append(
                    SubtitleProfile(
                        format: SubtitleFormat.vtt.rawValue,
                        method: .hls
                    )
                )

                return subtitles
            }(),
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
                    audioCodec: AudioCodec.unwrap(
                        [
                            .aac,
                            .ac3,
                            .alac,
                            .amr_nb,
                            .amr_wb,
                            .dts,
                            .eac3,
                            .flac,
                            .mp1,
                            .mp2,
                            .mp3,
                            .nellymoser,
                            .opus,
                            .pcm_alaw,
                            .pcm_bluray,
                            .pcm_dvd,
                            .pcm_mulaw,
                            .pcm_s16be,
                            .pcm_s16le,
                            .pcm_s24be,
                            .pcm_s24le,
                            .pcm_u8,
                            .speex,
                            .vorbis,
                            .wavpack,
                            .wmalossless,
                            .wmapro,
                            .wmav1,
                            .wmav2,
                        ]
                    ),
                    type: .video
                ),
            ],
            transcodingProfiles: [
                TranscodingProfile(
                    audioCodec: AudioCodec.unwrap(
                        [
                            .aac,
                            .ac3,
                            .alac,
                            .dts,
                            .eac3,
                            .flac,
                            .mp1,
                            .mp2,
                            .mp3,
                            .opus,
                            .vorbis,
                        ]
                    ),
                    isBreakOnNonKeyFrames: true,
                    container: MediaContainer.mp4.rawValue,
                    context: .streaming,
                    maxAudioChannels: "8",
                    minSegments: 2,
                    protocol: StreamType.hls.rawValue,
                    type: .video,
                    videoCodec: VideoCodec.unwrap(
                        [
                            .av1,
                            .h263,
                            .h264,
                            .hevc,
                            .mjpeg,
                            .mpeg1video,
                            .mpeg2video,
                            .mpeg4,
                            .vc1,
                            .vp9,
                        ]
                    )
                ),
            ],
            subtitleProfiles: {
                var subtitles = [SubtitleProfile]()

                subtitles.append(
                    contentsOf:
                    SubtitleFormat.unwrap(
                        subtitleDeliveryMethod: .embed,
                        [
                            .ass,
                            .cc_dec,
                            .dvbsub,
                            .dvdsub,
                            .jacosub,
                            .libzvbi_teletextdec,
                            .mov_text,
                            .mpl2,
                            .pgssub,
                            .pjs,
                            .realtext,
                            .sami,
                            .ssa,
                            .subrip,
                            .subviewer,
                            .subviewer1,
                            .text,
                            .ttml,
                            .vplayer,
                            .vtt,
                            .xsub,
                        ]
                    )
                )

                subtitles.append(
                    contentsOf:
                    SubtitleFormat.unwrap(
                        subtitleDeliveryMethod: .external,
                        [
                            .ass,
                            .dvbsub,
                            .dvdsub,
                            .jacosub,
                            .libzvbi_teletextdec,
                            .mpl2,
                            .pgssub,
                            .pjs,
                            .realtext,
                            .sami,
                            .ssa,
                            .subrip,
                            .subviewer,
                            .subviewer1,
                            .text,
                            .ttml,
                            .vplayer,
                            .vtt,
                            .xsub,
                        ]
                    )
                )

                return subtitles
            }(),
            codecProfiles: self.sharedCodecProfiles(),
            responseProfiles: self.sharedResponseProfiles()
        )
    }

    // MARK: - Shared Codec Profiles

    static func sharedCodecProfiles() -> [CodecProfile] {
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

    // MARK: - Compatibility Profiles

    static func compatibilityDirectPlayProfile() -> [DirectPlayProfile] {
        [
            DirectPlayProfile(
                audioCodec: AudioCodec.aac.rawValue,
                container: MediaContainer.mp4.rawValue,
                type: .video,
                videoCodec: VideoCodec.h264.rawValue
            ),
        ]
    }

    static func compatibilityTranscodingProfile() -> [TranscodingProfile] {
        [
            TranscodingProfile(
                audioCodec: AudioCodec.aac.rawValue,
                isBreakOnNonKeyFrames: true,
                container: MediaContainer.mp4.rawValue,
                context: .streaming,
                maxAudioChannels: "8",
                minSegments: 2,
                protocol: StreamType.hls.rawValue,
                type: .video,
                videoCodec: VideoCodec.h264.rawValue
            ),
        ]
    }

    // MARK: - Direct Profile

    static func forcedDirectPlayProfile() -> [DirectPlayProfile] {
        [
            DirectPlayProfile(type: .video),
        ]
    }
}
