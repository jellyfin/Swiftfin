//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

/// - Note: Values reflect the FFmpeg decoders and demuxers enabled in the MPVUI Libmpv build
///   (`Build/Sources/MPVBuildCore/Recipes/FFmpegFlags.swift`), which is not a full FFmpeg build.
extension MediaPlayerType {

    // MARK: - Direct Play

    @ArrayBuilder<DirectPlayProfile>
    static var _mpvDirectPlayProfiles: [DirectPlayProfile] {
        DirectPlayProfile(
            audioCodec: mpvAudioCodecs.map(\.rawValue).joined(separator: ","),
            container: "aac,ac3,aiff,amr,asf,caf,eac3,flac,m4a,m4b,mka,mkv,mov,mp3,mp4,oga,ogg,opus,wav,webm",
            type: .audio
        )

        DirectPlayProfile(type: .video) {
            mpvAudioCodecs
        } videoCodecs: {

            /// This is possible with non-AV1 supported devices but the FPS is terrible on some devices
            ///  - Defaulting to disabled but can be enabled in custom profiles if desired.
            if UIDevice.PlaybackCapabilities.supportsAV1 {
                VideoCodec.av1
            }

            VideoCodec.ffv1
            VideoCodec.flv1
            VideoCodec.h263
            VideoCodec.h264
            VideoCodec.hevc
            VideoCodec.mjpeg
            VideoCodec.mpeg1video
            VideoCodec.mpeg2video
            VideoCodec.mpeg4
            VideoCodec.prores
            VideoCodec.vc1
            VideoCodec.vp8
            VideoCodec.vp9
            VideoCodec.wmv1
            VideoCodec.wmv2
            VideoCodec.wmv3
        } containers: {
            MediaContainer.avi
            MediaContainer.flv
            MediaContainer.m4v
            MediaContainer.mkv
            MediaContainer.mov
            MediaContainer.mp4
            MediaContainer.mpegts
            MediaContainer.ts
            MediaContainer.threeG2
            MediaContainer.threeGP
            MediaContainer.webm
        }
    }

    // MARK: - Transcoding

    @ArrayBuilder<TranscodingProfile>
    static var _mpvTranscodingProfiles: [TranscodingProfile] {
        TranscodingProfile(
            protocol: .http,
            audioCodec: AudioCodec.mp3.rawValue,
            container: "mp3",
            context: .streaming,
            type: .audio
        )

        TranscodingProfile(
            isBreakOnNonKeyFrames: true,
            context: .streaming,
            maxAudioChannels: "8",
            minSegments: 2,
            protocol: MediaStreamProtocol.hls,
            type: .video
        ) {
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
            AudioCodec.dts
            AudioCodec.eac3
            AudioCodec.flac
            AudioCodec.mp3
            AudioCodec.opus
            AudioCodec.truehd
        } videoCodecs: {

            /// - Note: Transcode Profiles prioritizes codecs by order
            /// This is possible with non-AV1 supported devices but the FPS is terrible on some devices
            ///  - Defaulting to disabled but can be enabled in custom profiles if desired.
            if UIDevice.PlaybackCapabilities.supportsAV1 {
                VideoCodec.av1
            }

            VideoCodec.h264
            VideoCodec.hevc
            VideoCodec.vp9
        } containers: {
            MediaContainer.mp4
        }
    }

    // MARK: - Subtitle

    @ArrayBuilder<SubtitleProfile>
    static var _mpvSubtitleProfiles: [SubtitleProfile] {
        SubtitleProfile.build(method: .embed) {
            SubtitleFormat.ass
            SubtitleFormat.cc_dec
            SubtitleFormat.dvbsub
            SubtitleFormat.dvdsub
            SubtitleFormat.mov_text
            SubtitleFormat.mpl2
            SubtitleFormat.pgssub
            SubtitleFormat.ssa
            SubtitleFormat.subrip
            SubtitleFormat.vtt
            SubtitleFormat.xsub
        }

        /// - Note: Sidecar files are opened with `sub-add`, so only formats with an enabled demuxer are listed
        /// - Note: Unmatched text subtitles are converted to the first option (subrip)
        SubtitleProfile.build(method: .external) {
            SubtitleFormat.subrip
            SubtitleFormat.ass
            SubtitleFormat.ssa
            SubtitleFormat.vtt
        }

        SubtitleProfile.build(method: .encode) {
            SubtitleFormat.dvbsub
            SubtitleFormat.dvdsub
            SubtitleFormat.pgssub
            SubtitleFormat.vtt
            SubtitleFormat.xsub
        }
    }

    // MARK: - Codec Profiles

    @MainActor
    @ArrayBuilder<CodecProfile>
    static func _mpvCodecProfiles(configuration: MediaPlaybackConfiguration) -> [CodecProfile] {
        CodecProfile(
            codec: VideoCodec.h264.rawValue,
            type: .video,
            conditions: {
                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isAnamorphic,
                    value: "true"
                )

                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: false,
                    property: .videoProfile
                ) {
                    H264Profile.high
                    H264Profile.high10
                    H264Profile.main
                    H264Profile.baseline
                    H264Profile.constrainedBaseline
                }

                ProfileCondition(
                    condition: .lessThanEqual,
                    isRequired: false,
                    property: .videoLevel,
                    value: "80"
                )

                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: true,
                    property: .videoRangeType
                ) {
                    VideoRangeType.sdr
                }
            }
        )

        CodecProfile(
            codec: VideoCodec.hevc.rawValue,
            type: .video,
            conditions: {
                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isAnamorphic,
                    value: "true"
                )

                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: false,
                    property: .videoProfile
                ) {
                    HEVCProfile.main
                    HEVCProfile.main10
                }

                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isInterlaced,
                    value: "true"
                )

                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: true,
                    property: .videoRangeType
                ) {
                    mpvHEVCHDRProfiles(configuration: configuration)
                }
            }
        )

        CodecProfile(
            codec: VideoCodec.av1.rawValue,
            type: .video,
            conditions: {
                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isAnamorphic,
                    value: "true"
                )

                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isInterlaced,
                    value: "true"
                )

                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: true,
                    property: .videoRangeType
                ) {
                    mpvHDRProfiles(configuration: configuration)
                }
            }
        )

        CodecProfile(
            codec: VideoCodec.vp9.rawValue,
            type: .video,
            conditions: {
                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isAnamorphic,
                    value: "true"
                )

                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isInterlaced,
                    value: "true"
                )

                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: true,
                    property: .videoRangeType
                ) {
                    mpvHDRProfiles(configuration: configuration)
                }
            }
        )
    }

    /// MPVUI uses AVFoundation sample buffers by default, not `gpu-next`.
    /// HDR output depends on the display route. Accepting a source does not guarantee native HDR presentation.
    @MainActor
    @ArrayBuilder<VideoRangeType>
    private static func mpvHDRProfiles(configuration: MediaPlaybackConfiguration) -> [VideoRangeType] {

        VideoRangeType.sdr

        if !configuration.forceHDRTranscode {
            VideoRangeType.hlg
            VideoRangeType.hdr10
            VideoRangeType.hdr10Plus
        }
    }

    /// Native Dolby Vision in MPVUI's strict policy supports HEVC Profile 5 and Profile 8 HDR10/HLG bases.
    /// Profile 7 enhancement layers, SDR bases, and software Dolby Vision require a different rendering policy.
    @MainActor
    @ArrayBuilder<VideoRangeType>
    private static func mpvHEVCHDRProfiles(configuration: MediaPlaybackConfiguration) -> [VideoRangeType] {
        mpvHDRProfiles(configuration: configuration)

        if !configuration.forceHDRTranscode, !configuration.forceDVTranscode, UIDevice.PlaybackCapabilities.supportsDolbyVisionDecoding {
            VideoRangeType.dovi
            VideoRangeType.doviWithHLG
            VideoRangeType.doviWithHDR10
            VideoRangeType.doviWithHDR10Plus
        }
    }

    @ArrayBuilder<AudioCodec>
    private static var mpvAudioCodecs: [AudioCodec] {
        AudioCodec.aac
        AudioCodec.ac3
        AudioCodec.alac
        AudioCodec.amr_nb
        AudioCodec.amr_wb
        AudioCodec.dts
        AudioCodec.dts_hd
        AudioCodec.eac3
        AudioCodec.flac
        AudioCodec.mp1
        AudioCodec.mp2
        AudioCodec.mp3
        AudioCodec.opus
        AudioCodec.pcm_alaw
        AudioCodec.pcm_bluray
        AudioCodec.pcm_dvd
        AudioCodec.pcm_mulaw
        AudioCodec.pcm_s16be
        AudioCodec.pcm_s16le
        AudioCodec.pcm_s24be
        AudioCodec.pcm_s24le
        AudioCodec.pcm_u8
        AudioCodec.truehd
        AudioCodec.vorbis
        AudioCodec.wmalossless
        AudioCodec.wmapro
        AudioCodec.wmav1
        AudioCodec.wmav2
    }
}
