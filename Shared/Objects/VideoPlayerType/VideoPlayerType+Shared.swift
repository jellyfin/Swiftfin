//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension VideoPlayerType {

    // MARK: codec profiles

    @ArrayBuilder<CodecProfile>
    var codecProfiles: [CodecProfile] {
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

    // MARK: - response profiles

    @ArrayBuilder<ResponseProfile>
    var responseProfiles: [ResponseProfile] {
        ResponseProfile(
            container: MediaContainer.m4v.rawValue,
            mimeType: "video/mp4",
            type: .video
        )
    }
}
