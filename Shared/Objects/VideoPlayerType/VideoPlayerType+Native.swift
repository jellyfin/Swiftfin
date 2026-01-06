//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension VideoPlayerType {

    // MARK: - Direct Play

    @ArrayBuilder<DirectPlayProfile>
    static var _nativeDirectPlayProfiles: [DirectPlayProfile] {

        DirectPlayProfile(type: .video) {
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
            AudioCodec.eac3
            AudioCodec.flac
        } videoCodecs: {

            VideoCodec.h264
            VideoCodec.mpeg4

            if DeviceGPU.supportsAV1 {
                VideoCodec.av1
            }
            if DeviceGPU.supportsHEVC {
                VideoCodec.hevc
            }
            if DeviceGPU.supportsVP9 {
                VideoCodec.vp9
            }

        } containers: {
            MediaContainer.mp4
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
            VideoCodec.mjpeg
            VideoCodec.mpeg4

            if DeviceGPU.supportsHEVC {
                VideoCodec.hevc
            }

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

            if DeviceGPU.supportsHEVC {
                VideoCodec.hevc
            }

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

    // MARK: - Transcoding

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
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
            AudioCodec.eac3
            AudioCodec.flac
        } videoCodecs: {

            /// Notice: Transcode Profiles prioritizes codecs by order
            if DeviceGPU.supportsAV1 {
                VideoCodec.av1
            }
            if DeviceGPU.supportsHEVC {
                VideoCodec.hevc
            }

            VideoCodec.h264
            VideoCodec.mpeg4

        } containers: {
            MediaContainer.mp4
        }
    }

    // MARK: - Subtitle

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

    // MARK: - Codec Profiles

    @ArrayBuilder<CodecProfile>
    static var _nativeCodecProfiles: [CodecProfile] {

        CodecProfile(
            codec: VideoCodec.h264.rawValue,
            type: .video,
            conditions: {
                _h264BaseConditions
                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: false,
                    property: .videoRangeType
                ) {
                    VideoRangeType.sdr
                    VideoRangeType.doviWithSDR
                }
            }
        )

        CodecProfile(
            codec: VideoCodec.hevc.rawValue,
            type: .video,
            conditions: {
                _hevcBaseConditions
                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: false,
                    property: .videoRangeType
                ) {
                    nativeHDRProfiles
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
                    isRequired: false,
                    property: .videoRangeType
                ) {
                    nativeHDRProfiles
                }
            }
        )
    }

    @ArrayBuilder<VideoRangeType>
    private static var nativeHDRProfiles: [VideoRangeType] {

        VideoRangeType.sdr
        VideoRangeType.doviWithSDR

        if DeviceGPU.supportsHLG {
            VideoRangeType.hlg
            VideoRangeType.doviWithHLG
        }

        if DeviceGPU.supportsHDR10 {
            VideoRangeType.hdr10
            VideoRangeType.hdr10Plus
        }

        if DeviceGPU.supportsHDR10 || DeviceGPU.supportsDolbyVision {
            VideoRangeType.doviWithHDR10
            VideoRangeType.doviWithHDR10Plus
        }

        if DeviceGPU.supportsDolbyVision {
            VideoRangeType.dovi
        }
    }
}
