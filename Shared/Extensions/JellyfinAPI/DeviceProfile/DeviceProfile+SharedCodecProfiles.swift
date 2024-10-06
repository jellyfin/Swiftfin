//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension DeviceProfile {

    // For now, assume native and VLCKit support same codec conditions
    static func sharedCodecProfiles() -> [CodecProfile] {

        var codecProfiles: [CodecProfile] = []

        let h264CodecConditions: [ProfileCondition] = [
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

        codecProfiles.append(CodecProfile(applyConditions: h264CodecConditions, codec: "h264", type: .video))

        let hevcCodecConditions: [ProfileCondition] = [
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

        codecProfiles.append(CodecProfile(applyConditions: hevcCodecConditions, codec: "hevc", type: .video))

        return codecProfiles
    }
}
