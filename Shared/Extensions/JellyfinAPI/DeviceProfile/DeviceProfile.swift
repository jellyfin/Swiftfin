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
        useCustomDirectPlayProfile: CustomDeviceProfileAction = .off,
        useCustomTranscodingProfile: Bool = false
    ) -> DeviceProfile {

        var deviceProfile: DeviceProfile = .init()

        deviceProfile.codecProfiles = videoPlayer.codecProfiles
        deviceProfile.responseProfiles = videoPlayer.responseProfiles
        deviceProfile.subtitleProfiles = videoPlayer.subtitleProfiles

        if useCustomTranscodingProfile {
            deviceProfile.transcodingProfiles = {
                switch useCustomDirectPlayProfile {
                case .replace:
                    return customTranscodingProfile()
                case .off:
                    return videoPlayer.transcodingProfiles
                case .add:
                    return videoPlayer.transcodingProfiles + customTranscodingProfile()
                }
            }()
        } else {
            deviceProfile.transcodingProfiles = videoPlayer.transcodingProfiles
        }

        deviceProfile.directPlayProfiles = {
            switch useCustomDirectPlayProfile {
            case .replace:
                return customDirectPlayProfile()
            case .off:
                return videoPlayer.directPlayProfiles
            case .add:
                return videoPlayer.directPlayProfiles + customDirectPlayProfile()
            }
        }()

        if let maxBitrate {
            deviceProfile.maxStaticBitrate = maxBitrate
            deviceProfile.maxStreamingBitrate = maxBitrate
            deviceProfile.musicStreamingTranscodingBitrate = maxBitrate
        }

        return deviceProfile
    }
}
