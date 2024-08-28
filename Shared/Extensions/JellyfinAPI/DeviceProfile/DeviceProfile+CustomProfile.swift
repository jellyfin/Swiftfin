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

extension DeviceProfile {
    static func customDirectPlayProfile() -> [DirectPlayProfile] {
        var customAudioProfile = StoredValues[.User.customDeviceProfileAudio()]
        var customVideoProfile = StoredValues[.User.customDeviceProfileVideo()]
        var customContainers = StoredValues[.User.customDeviceProfileContainers()]

        var customProfile: DirectPlayProfile

        customProfile = DirectPlayProfile(
            audioCodec: customAudioProfile.map(\.rawValue).joined(separator: ","),
            container: customContainers.map(\.rawValue).joined(separator: ","),
            type: .video,
            videoCodec: customVideoProfile.map(\.rawValue).joined(separator: ",")
        )

        return [customProfile]
    }

    static func customTranscodingProfile() -> [TranscodingProfile] {
        var customAudioProfile = StoredValues[.User.customDeviceProfileAudio()]
        var customVideoProfile = StoredValues[.User.customDeviceProfileVideo()]
        var customContainers = StoredValues[.User.customDeviceProfileContainers()]

        var customProfile: TranscodingProfile

        customProfile = TranscodingProfile(
            audioCodec: customAudioProfile.map(\.rawValue).joined(separator: ","),
            isBreakOnNonKeyFrames: true,
            container: customContainers.map(\.rawValue).joined(separator: ","),
            context: .streaming,
            maxAudioChannels: "8",
            minSegments: 2,
            protocol: StreamType.hls.rawValue,
            type: .video,
            videoCodec: customVideoProfile.map(\.rawValue).joined(separator: ",")
        )

        return [customProfile]
    }
}
