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
        for playerType: MediaPlayerType,
        compatibilityMode: PlaybackCompatibility,
        maxBitrate: Int? = nil,
        maxResolution: PlaybackResolution = Defaults[.VideoPlayer.Playback.appMaximumResolution],
        mediaSource: MediaSourceInfo? = nil
    ) -> DeviceProfile {

        var deviceProfile: DeviceProfile = .init()

        // MARK: - Media Player Specific Logic

        deviceProfile.codecProfiles = playerType.codecProfiles

        if StoredValues[.User.forceSubtitleBurnIn] {
            deviceProfile.subtitleProfiles = SubtitleProfile.build(method: .encode) {
                SubtitleFormat.allCases
            }
        } else {
            deviceProfile.subtitleProfiles = playerType.subtitleProfiles
        }

        // To preserve native Dolby Vision pixels in MPVUI, subtitles must use our text
        // overlay or server burn-in instead of native ASS/bitmap composition.
        if playerType == .mpv,
           mediaSource?.mediaStreams?.contains(where: {
               $0.type == .video && ($0.dvProfile != nil || $0.videoRangeType?.isDolbyVision == true)
           }) == true
        {
            deviceProfile.subtitleProfiles = deviceProfile.subtitleProfiles?.filter {
                $0.method == .encode || ($0.method == .external && ["subrip", "vtt"].contains($0.format ?? ""))
            }
        }

        if let resolutionCodecProfile = maxResolution.codecProfile {
            deviceProfile.codecProfiles?.append(resolutionCodecProfile)
        }

        // MARK: - DirectPlay & Transcoding Profiles

        switch compatibilityMode {
        case .auto:
            deviceProfile.directPlayProfiles = playerType.directPlayProfiles
            deviceProfile.transcodingProfiles = playerType.transcodingProfiles

        case .mostCompatible:
            deviceProfile.directPlayProfiles = PlaybackCompatibility.Video.compatibilityDirectPlayProfile
            deviceProfile.transcodingProfiles = PlaybackCompatibility.Video.compatibilityTranscodingProfile

        case .directPlay:
            deviceProfile.directPlayProfiles = PlaybackCompatibility.Video.forcedDirectPlayProfile

        case .custom:
            let customProfileMode = Defaults[.VideoPlayer.Playback.customDeviceProfileAction]
            let playbackDeviceProfile = StoredValues[.User.customDeviceProfiles]

            if customProfileMode == .add {
                deviceProfile.directPlayProfiles = playerType.directPlayProfiles
                deviceProfile.transcodingProfiles = playerType.transcodingProfiles
            } else {
                deviceProfile.directPlayProfiles = []

                // Only clear the Transcoding Profiles if one of the CustomProfiles is active as a Transcoding Profile
                if playbackDeviceProfile.contains(where: { $0.useAsTranscodingProfile == true }) {
                    deviceProfile.transcodingProfiles = []
                } else {
                    deviceProfile.transcodingProfiles = playerType.transcodingProfiles
                }
            }

            for profile in playbackDeviceProfile where profile.type == .video {
                deviceProfile.directPlayProfiles?.append(profile.directPlayProfile)

                if profile.useAsTranscodingProfile {
                    deviceProfile.transcodingProfiles?.append(profile.transcodingProfile)
                }
            }
        }

        // Retain each engine's audio support when applying compatibility and custom video profile settings.
        if deviceProfile.directPlayProfiles?.contains(where: { $0.type == .audio }) != true {
            deviceProfile.directPlayProfiles = (deviceProfile.directPlayProfiles ?? [])
                + playerType.directPlayProfiles.filter { $0.type == .audio }
        }

        if compatibilityMode != .directPlay,
           deviceProfile.transcodingProfiles?.contains(where: { $0.type == .audio }) != true
        {
            deviceProfile.transcodingProfiles = (deviceProfile.transcodingProfiles ?? [])
                + playerType.transcodingProfiles.filter { $0.type == .audio }
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
