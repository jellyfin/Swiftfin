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

    case airPlayVideo
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
        case .airPlayVideo:
            true
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
        case .airPlayVideo:
            let subtitleProfiles: [SubtitleProfile] = if configuration.forceSubtitleBurnIn {
                SubtitleProfile.build(method: .encode) { SubtitleFormat.allCases }
            } else {
                SubtitleProfile.build(method: .hls) { SubtitleFormat.vtt }
            }

            return Self.compatibleHLSProfile(
                name: "AirPlay",
                subtitleProfiles: subtitleProfiles,
                enableSubtitlesInManifest: true,
                codecProfiles: [
                    CodecProfile(codec: "h264", type: .video, conditions: {
                        ProfileCondition(condition: .notEquals, isRequired: false, property: .isInterlaced, value: "true")
                    }),
                ],
                configuration: configuration,
                maxBitrate: maxBitrate,
                mediaSource: mediaSource
            )

        #if os(iOS)
        case .chromecast:
            // The Default Media Receiver cannot negotiate device-specific codecs.
            // HLS also lets Jellyfin select audio and burn subtitles without guessing Cast track IDs.
            return Self.compatibleHLSProfile(
                name: "Chromecast",
                subtitleProfiles: SubtitleProfile.build(method: .encode) { SubtitleFormat.allCases },
                configuration: configuration,
                maxBitrate: maxBitrate,
                mediaSource: mediaSource
            )
        #endif

        case let .local(player):
            return .build(for: player, configuration: configuration, maxBitrate: maxBitrate, mediaSource: mediaSource)
        }
    }

    /// Receivers that cannot negotiate codecs get one conservative H.264/AAC HLS stream.
    private static func compatibleHLSProfile(
        name: String,
        subtitleProfiles: [SubtitleProfile],
        enableSubtitlesInManifest: Bool? = nil,
        codecProfiles additionalCodecProfiles: [CodecProfile] = [],
        configuration: MediaPlaybackConfiguration,
        maxBitrate: Int,
        mediaSource: MediaSourceInfo
    ) -> DeviceProfile {
        var profile = DeviceProfile()
        profile.name = name
        profile.maxStreamingBitrate = min(maxBitrate, 20_000_000)
        profile.maxStaticBitrate = profile.maxStreamingBitrate
        profile.directPlayProfiles = []
        profile.transcodingProfiles = [
            TranscodingProfile(
                protocol: .hls,
                audioCodec: "aac",
                container: "ts",
                context: .streaming,
                enableSubtitlesInManifest: enableSubtitlesInManifest,
                maxAudioChannels: "2",
                minSegments: 2,
                type: .video,
                videoCodec: "h264"
            ),
        ]
        profile.subtitleProfiles = subtitleProfiles
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
        ] + additionalCodecProfiles

        if let resolutionProfile = maxResolution.codecProfile(for: mediaSource) {
            profile.codecProfiles?.append(resolutionProfile)
        }

        return profile
    }
}
