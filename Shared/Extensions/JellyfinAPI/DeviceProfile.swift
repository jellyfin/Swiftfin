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

    #if os(iOS)
    static func audioPlayer(maxBitrate: Int? = nil) -> DeviceProfile {
        var deviceProfile = DeviceProfile()

        deviceProfile.directPlayProfiles = [
            DirectPlayProfile(
                audioCodec: "aac",
                container: "aac",
                type: .audio
            ),
            DirectPlayProfile(
                audioCodec: "flac",
                container: "flac",
                type: .audio
            ),
            DirectPlayProfile(
                audioCodec: "aac,ac3,alac,eac3,mp3",
                container: "m4a,m4b,mov,mp4",
                type: .audio
            ),
            DirectPlayProfile(
                audioCodec: "mp3",
                container: "mp3",
                type: .audio
            ),
            DirectPlayProfile(
                audioCodec: "pcm_mulaw,pcm_s16be,pcm_s16le,pcm_s24be,pcm_s24le",
                container: "wav",
                type: .audio
            ),
        ]
        deviceProfile.transcodingProfiles = [
            TranscodingProfile(
                protocol: .http,
                audioCodec: "aac",
                container: "aac",
                context: .streaming,
                maxAudioChannels: "2",
                type: .audio
            ),
        ]

        if let maxBitrate {
            deviceProfile.maxStaticBitrate = maxBitrate
            deviceProfile.maxStreamingBitrate = maxBitrate
            deviceProfile.musicStreamingTranscodingBitrate = maxBitrate
        }

        return deviceProfile
    }
    #endif

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

    // MARK: - Playback Capability Queries

    /// Whether any `DirectPlayProfile` allows media with this audio codec in the given container to be played directly.
    func canPlay(type: DlnaProfileType, audioCodec: String?, container: String?) -> Bool {
        (directPlayProfiles ?? []).contains { profile in
            profile.type == type
                && profileContains(profile: profile.audioCodec, audioCodec)
                && profileContains(profile: profile.container, container)
        }
    }

    /// Whether any `DirectPlayProfile` allows media with this video codec in the given container to be played directly.
    func canPlay(type: DlnaProfileType, videoCodec: String?, container: String?) -> Bool {
        (directPlayProfiles ?? []).contains { profile in
            profile.type == type
                && profileContains(profile: profile.videoCodec, videoCodec)
                && profileContains(profile: profile.container, container)
        }
    }

    /// Whether any `SubtitleProfile` allows this format to be delivered via the given method.
    func canPlay(subtitleFormat: String?, method: SubtitleDeliveryMethod) -> Bool {
        guard let subtitleFormat = subtitleFormat?.lowercased() else { return false }
        return (subtitleProfiles ?? []).contains { profile in
            profile.method == method
                && profile.format?.lowercased() == subtitleFormat
        }
    }

    /// Parse & check membership like this is CSV as that's the format we send to the server.
    private func profileContains(profile: String?, _ candidate: String?) -> Bool {
        guard let profile else { return true }
        guard let candidate = candidate?.lowercased() else { return false }
        return profile
            .lowercased()
            .split(separator: ",")
            .contains { $0.trimmingCharacters(in: .whitespaces) == candidate }
    }
}
