//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension DeviceProfile {

    static func build(
        for videoPlayer: VideoPlayerType,
        maxBitrate: Int? = nil,
        useCustomProfile: CustomDeviceProfileSelection = .off
    ) -> DeviceProfile {

        var deviceProfile: DeviceProfile

        switch videoPlayer {
        case .native:
            deviceProfile = nativeProfile()
        case .swiftfin:
            deviceProfile = swiftfinProfile()
        }

        switch useCustomProfile {
        case .add:
            deviceProfile.directPlayProfiles?.append(contentsOf: customProfile())
        case .replace:
            deviceProfile.directPlayProfiles = customProfile()
        case .off:
            break
        }

        let codecProfiles: [CodecProfile] = sharedCodecProfiles()

        let responseProfiles: [ResponseProfile] = [
            ResponseProfile(
                container: MediaContainer.m4v.rawValue,
                mimeType: "video/mp4",
                type: .video
            ),
        ]

        deviceProfile.codecProfiles = codecProfiles
        deviceProfile.responseProfiles = responseProfiles

        if let maxBitrate {
            deviceProfile.maxStaticBitrate = maxBitrate
            deviceProfile.maxStreamingBitrate = maxBitrate
            deviceProfile.musicStreamingTranscodingBitrate = maxBitrate
        }

        return deviceProfile
    }
}
