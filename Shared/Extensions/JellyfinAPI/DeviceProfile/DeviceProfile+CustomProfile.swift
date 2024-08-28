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
        let customAudioProfile = StoredValues[.User.customDeviceProfileAudio()]
        let customVideoProfile = StoredValues[.User.customDeviceProfileVideo()]
        let customContainers = StoredValues[.User.customDeviceProfileContainers()]

        var customProfile: DirectPlayProfile

        customProfile = DirectPlayProfile(
            audioCodec: AudioCodec.unwrap(customAudioProfile),
            container: MediaContainer.unwrap(customContainers),
            type: .video,
            videoCodec: VideoCodec.unwrap(customVideoProfile)
        )

        return [customProfile]
    }

    static func customTranscodingProfile() -> [TranscodingProfile] {
        let customAudioProfile = StoredValues[.User.customDeviceProfileAudio()]
        let customVideoProfile = StoredValues[.User.customDeviceProfileVideo()]
        let customContainers = StoredValues[.User.customDeviceProfileContainers()]

        var customProfile: TranscodingProfile

        customProfile = TranscodingProfile(
            audioCodec: AudioCodec.unwrap(customAudioProfile),
            isBreakOnNonKeyFrames: true,
            container: MediaContainer.unwrap(customContainers),
            context: .streaming,
            maxAudioChannels: "8",
            minSegments: 2,
            protocol: StreamType.hls.rawValue,
            type: .video,
            videoCodec: VideoCodec.unwrap(customVideoProfile)
        )

        return [customProfile]
    }
}
