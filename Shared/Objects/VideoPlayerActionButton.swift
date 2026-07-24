//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// TODO: add playbackQuality
// TODO: add audio/subtitle offset

enum VideoPlayerActionButton: String, CaseIterable, Displayable, Equatable, Identifiable, Storable, SystemImageable {

    case aspectFill
    case audio
    case autoPlay
    case pictureInPicture
    case playbackSpeed
    case playbackSettings
    case playNextItem
    case playPreviousItem
    case remotePlayback
    case subtitles
    #if os(iOS)
    case gestureLock
    #endif

    var displayTitle: String {
        switch self {
        case .aspectFill:
            L10n.aspectFill
        case .audio:
            L10n.audio
        case .autoPlay:
            L10n.autoPlay
        case .pictureInPicture:
            L10n.pictureInPicture
        case .playbackSpeed:
            L10n.playbackSpeed
        case .playbackSettings:
            L10n.playback
        case .playNextItem:
            L10n.playNextItem
        case .playPreviousItem:
            L10n.playPreviousItem
        case .remotePlayback:
            L10n.outputs
        case .subtitles:
            L10n.subtitles
        #if os(iOS)
        case .gestureLock:
            L10n.gestureLock
        #endif
        }
    }

    var id: String {
        rawValue
    }

    #if os(tvOS)
    var systemImage: String {
        switch self {
        case .aspectFill: "arrow.up.left.and.arrow.down.right"
        case .audio: "speaker.wave.2"
        case .autoPlay: "play.fill"
        case .pictureInPicture: "pip.enter"
        case .playbackSpeed: "speedometer"
        case .playbackSettings: "tv.circle.fill"
        case .playNextItem: "forward.end.fill"
        case .playPreviousItem: "backward.end.fill"
        case .remotePlayback: "airplayvideo"
        case .subtitles: "captions.bubble.fill"
        }
    }

    var secondarySystemImage: String {
        switch self {
        case .aspectFill: "arrow.down.right.and.arrow.up.left"
        case .audio: "speaker.wave.2"
        case .autoPlay: "stop.fill"
        case .pictureInPicture: "pip.exit"
        case .subtitles: "captions.bubble"
        default:
            systemImage
        }
    }
    #else
    var systemImage: String {
        switch self {
        case .aspectFill: "arrow.up.left.and.arrow.down.right"
        case .audio: "speaker.wave.2.fill"
        case .autoPlay: "play.circle.fill"
        case .gestureLock: "lock.circle.fill"
        case .pictureInPicture: "pip.enter"
        case .playbackSpeed: "speedometer"
        case .playbackSettings: "tv.circle.fill"
        case .playNextItem: "forward.end.circle.fill"
        case .playPreviousItem: "backward.end.circle.fill"
        case .remotePlayback: "airplayvideo"
        case .subtitles: "captions.bubble.fill"
        }
    }

    var secondarySystemImage: String {
        switch self {
        case .aspectFill: "arrow.down.right.and.arrow.up.left"
        case .audio: "speaker.wave.2"
        case .autoPlay: "stop.circle"
        case .gestureLock: "lock.open.fill"
        case .pictureInPicture: "pip.exit"
        case .subtitles: "captions.bubble"
        default:
            systemImage
        }
    }
    #endif

    static let defaultBarActionButtons: [VideoPlayerActionButton] = [
        .aspectFill,
        .autoPlay,
        .playPreviousItem,
        .playNextItem,
        .remotePlayback,
    ]

    static let defaultMenuActionButtons: [VideoPlayerActionButton] = [
        .audio,
        .subtitles,
        .playbackSpeed,
        .pictureInPicture,
        .playbackSettings,
    ]
}
