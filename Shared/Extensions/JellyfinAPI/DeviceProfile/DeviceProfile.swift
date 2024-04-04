//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension DeviceProfile {

    static func build(for videoPlayer: VideoPlayerType, maxBitrate: Int? = nil) -> DeviceProfile {

        var deviceProfile: DeviceProfile

        switch videoPlayer {
        case .native:
            deviceProfile = nativeProfile()
        case .swiftfin:
            deviceProfile = swiftfinProfile()
        }

        let codecProfiles: [CodecProfile] = sharedCodecProfiles()
        let responseProfiles: [ResponseProfile] = [ResponseProfile(container: "m4v", mimeType: "video/mp4", type: .video)]

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
