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

    // MARK: - Codec Profiles

    @ArrayBuilder<CodecProfile>
    var codecProfiles: [CodecProfile] {
        switch self {
        case .native:
            Self._nativeCodecProfiles
        case .swiftfin:
            Self._swiftfinCodecProfiles
        }
    }

    // MARK: - Shared Codec Profile Conditions

    @ArrayBuilder<ProfileCondition>
    static var _h264BaseConditions: [ProfileCondition] {
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
            condition: .notEquals,
            isRequired: false,
            property: .isInterlaced,
            value: "true"
        )
    }

    @ArrayBuilder<ProfileCondition>
    static var _hevcBaseConditions: [ProfileCondition] {
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
}
