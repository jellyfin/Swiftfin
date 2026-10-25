//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

@MainActor
enum PlaybackProfile: Equatable {

    #if os(iOS)
    case chromecast
    #endif
    case local(MediaPlayerType)

    var supportsSecondarySubtitles: Bool {
        switch self {
        case .local(.mpv):
            true
        default:
            false
        }
    }

    var requiresHLS: Bool {
        switch self {
        #if os(iOS)
        case .chromecast:
            true
        #endif
        case .local:
            false
        }
    }

    func deviceProfile(
        configuration: MediaPlaybackConfiguration,
        maxBitrate: Int,
        mediaSource: MediaSourceInfo
    ) -> DeviceProfile {
        switch self {
        #if os(iOS)
        case .chromecast:
            // The Default Media Receiver cannot negotiate device-specific codecs.
            // HLS also lets Jellyfin select audio and burn subtitles without guessing Cast track IDs.
            var profile = DeviceProfile()
            profile.name = "Chromecast"
            profile.maxStreamingBitrate = min(maxBitrate, 20_000_000)
            profile.maxStaticBitrate = profile.maxStreamingBitrate
            profile.directPlayProfiles = []
            profile.transcodingProfiles = [
                TranscodingProfile(
                    protocol: .hls,
                    audioCodec: "aac",
                    container: "ts",
                    context: .streaming,
                    maxAudioChannels: "2",
                    minSegments: 2,
                    type: .video,
                    videoCodec: "h264"
                ),
            ]
            profile.subtitleProfiles = SubtitleProfile.build(method: .encode) { SubtitleFormat.allCases }
            let requestedResolution = configuration.maxResolution
            let maxResolution: PlaybackResolution = requestedResolution == .max || requestedResolution.rawValue > 1080
                ? .p1080 : requestedResolution
            profile.codecProfiles = [
                CodecProfile(codec: "h264", type: .video, conditions: {
                    ProfileCondition(condition: .lessThanEqual, isRequired: true, property: .videoLevel, value: "41")
                    ProfileCondition(condition: .lessThanEqual, isRequired: true, property: .videoBitDepth, value: "8")
                    ProfileCondition(condition: .equalsAny, isRequired: true, property: .videoProfile, value: "baseline|main|high")
                    ProfileCondition(condition: .equalsAny, isRequired: true, property: .videoRangeType, value: "SDR")
                    ProfileCondition(condition: .lessThanEqual, isRequired: true, property: .videoFramerate, value: "30")
                    ProfileCondition(condition: .lessThanEqual, isRequired: true, property: .width, value: "1920")
                    ProfileCondition(condition: .lessThanEqual, isRequired: true, property: .height, value: "1080")
                }),
            ]

            if let resolutionProfile = maxResolution.codecProfile(for: mediaSource) {
                profile.codecProfiles?.append(resolutionProfile)
            }

            return profile
        #endif

        case let .local(player):
            return .build(for: player, configuration: configuration, maxBitrate: maxBitrate, mediaSource: mediaSource)
        }
    }
}
