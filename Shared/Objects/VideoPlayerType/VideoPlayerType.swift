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

    // MARK: - Shared Codec Profiles

    @ArrayBuilder<CodecProfile>
    static var sharedCodecProfiles: [CodecProfile] {
        CodecProfile(
            codec: VideoCodec.h264.rawValue,
            type: .video,
            applyConditions: {
                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isAnamorphic,
                    value: "true"
                )

                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: false,
                    property: .videoProfile,
                    value: "high|main|baseline|constrained baseline"
                )

                ProfileCondition(
                    condition: .lessThanEqual,
                    isRequired: false,
                    property: .videoLevel,
                    value: "80"
                )

                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isInterlaced,
                    value: "true"
                )
            }
        )

        CodecProfile(
            codec: VideoCodec.hevc.rawValue,
            type: .video,
            applyConditions: {
                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isAnamorphic,
                    value: "true"
                )

                ProfileCondition(
                    condition: .equalsAny,
                    isRequired: false,
                    property: .videoProfile,
                    value: "high|main|main 10"
                )

                ProfileCondition(
                    condition: .lessThanEqual,
                    isRequired: false,
                    property: .videoLevel,
                    value: "175"
                )

                ProfileCondition(
                    condition: .notEquals,
                    isRequired: false,
                    property: .isInterlaced,
                    value: "true"
                )
            }
        )
    }

    // MARK: - Shared Repsonse Profiles

    @ArrayBuilder<ResponseProfile>
    static var sharedResponseProfiles: [ResponseProfile] {
        ResponseProfile(
            container: MediaContainer.m4v.rawValue,
            mimeType: "video/mp4",
            type: .video
        )
    }

    // MARK: - Compatibility Profiles

    @ArrayBuilder<DirectPlayProfile>
    static func compatibilityDirectPlayProfile() -> [DirectPlayProfile] {
        DirectPlayProfile(type: .video) {
            AudioCodec.aac
        } videoCodecs: {
            VideoCodec.h264
        } containers: {
            MediaContainer.mp4
        }
    }

    @ArrayBuilder<TranscodingProfile>
    static var compatibilityTranscodingProfile: [TranscodingProfile] {
        TranscodingProfile(
            isBreakOnNonKeyFrames: true,
            context: .streaming,
            maxAudioChannels: "8",
            minSegments: 2,
            protocol: StreamType.hls.rawValue,
            type: .video
        ) {
            AudioCodec.aac
        } videoCodecs: {
            VideoCodec.h264
        } containers: {
            MediaContainer.mp4
        }
    }

    // MARK: - Direct Profile

    @ArrayBuilder<DirectPlayProfile>
    static func forcedDirectPlayProfile() -> [DirectPlayProfile] {
        DirectPlayProfile(type: .video)
    }
}
