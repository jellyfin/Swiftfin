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

        var deviceProfile: DeviceProfile = .init()

        deviceProfile.transcodingProfiles = videoPlayer.transcodingProfiles
        deviceProfile.codecProfiles = videoPlayer.codecProfiles
        deviceProfile.responseProfiles = videoPlayer.responseProfiles

        switch useCustomProfile {
        case .replace:
            deviceProfile.directPlayProfiles = customProfile()
        case .off:
            deviceProfile.directPlayProfiles = videoPlayer.directPlayProfiles
        case .add:
            deviceProfile.directPlayProfiles = videoPlayer.directPlayProfiles + customProfile()
        }

        if let maxBitrate {
            deviceProfile.maxStaticBitrate = maxBitrate
            deviceProfile.maxStreamingBitrate = maxBitrate
            deviceProfile.musicStreamingTranscodingBitrate = maxBitrate
        }

        return deviceProfile
    }
}
