//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

extension DeviceProfile {

    static func build(
        for videoPlayer: VideoPlayerType,
        compatibilityMode: PlaybackCompatibility,
        maxBitrate: Int? = nil
    ) -> DeviceProfile {

        var deviceProfile: DeviceProfile = .init()

        // MARK: - Video Player Specific Logic

        deviceProfile.codecProfiles = videoPlayer.codecProfiles
        deviceProfile.subtitleProfiles = videoPlayer.subtitleProfiles

        // MARK: - DirectPlay & Transcoding Profiles

        switch compatibilityMode {
        case .auto:
            deviceProfile.directPlayProfiles = videoPlayer.directPlayProfiles
            deviceProfile.transcodingProfiles = videoPlayer.transcodingProfiles

        case .mostCompatible:
            deviceProfile.directPlayProfiles = PlaybackCompatibility.Video.compatibilityDirectPlayProfile
            deviceProfile.transcodingProfiles = PlaybackCompatibility.Video.compatibilityTranscodingProfile

        case .directPlay:
            deviceProfile.directPlayProfiles = PlaybackCompatibility.Video.forcedDirectPlayProfile

        case .custom:
            let customProfileMode = Defaults[.VideoPlayer.Playback.customDeviceProfileAction]
            let playbackDeviceProfile = StoredValues[.User.customDeviceProfiles]

            if customProfileMode == .add {
                deviceProfile.directPlayProfiles = videoPlayer.directPlayProfiles
                deviceProfile.transcodingProfiles = videoPlayer.transcodingProfiles
            } else {
                deviceProfile.directPlayProfiles = []

                // Only clear the Transcoding Profiles if one of the CustomProfiles is active as a Transcoding Profile
                if playbackDeviceProfile.contains(where: { $0.useAsTranscodingProfile == true }) {
                    deviceProfile.transcodingProfiles = []
                } else {
                    deviceProfile.transcodingProfiles = videoPlayer.transcodingProfiles
                }
            }

            for profile in playbackDeviceProfile where profile.type == .video {
                deviceProfile.directPlayProfiles?.append(profile.directPlayProfile)

                if profile.useAsTranscodingProfile {
                    deviceProfile.transcodingProfiles?.append(profile.transcodingProfile)
                }
            }
        }

        // MARK: - Assign the Bitrate if provided

        if let maxBitrate {
            deviceProfile.maxStaticBitrate = maxBitrate
            deviceProfile.maxStreamingBitrate = maxBitrate
            deviceProfile.musicStreamingTranscodingBitrate = maxBitrate
        }

        return deviceProfile
    }
}
