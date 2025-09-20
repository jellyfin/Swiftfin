//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

// TODO: add audio/subtitle offset

enum VideoPlayerActionButton: String, CaseIterable, Displayable, Equatable, Identifiable, Storable, SystemImageable {

    case aspectFill
    case audio
    case autoPlay
    case gestureLock
    case playbackSpeed
//    case playbackQuality
    case playNextItem
    case playPreviousItem
    case subtitles

    var displayTitle: String {
        switch self {
        case .aspectFill:
            return L10n.aspectFill
        case .audio:
            return L10n.audio
        case .autoPlay:
            return L10n.autoPlay
        case .gestureLock:
            return L10n.gestureLock
        case .playbackSpeed:
            return L10n.playbackSpeed
//        case .playbackQuality:
//            return L10n.playbackQuality
        case .playNextItem:
            return L10n.playNextItem
        case .playPreviousItem:
            return L10n.playPreviousItem
        case .subtitles:
            return L10n.subtitles
        }
    }

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .aspectFill: "arrow.up.left.and.arrow.down.right"
        case .audio: "speaker.wave.2.fill"
        case .autoPlay: "play.circle.fill"
        case .gestureLock: "lock.circle.fill"
        case .playbackSpeed: "speedometer"
//        case .playbackQuality: "tv.circle.fill"
        case .playNextItem: "forward.end.circle.fill"
        case .playPreviousItem: "backward.end.circle.fill"
        case .subtitles: "captions.bubble.fill"
        }
    }

    var secondarySystemImage: String {
        switch self {
        case .aspectFill: "arrow.down.right.and.arrow.up.left"
        case .audio: "speaker.wave.2"
        case .autoPlay: "stop.circle"
        case .gestureLock: "lock.open.fill"
        case .subtitles: "captions.bubble"
        default:
            systemImage
        }
    }

    static let defaultBarActionButtons: [VideoPlayerActionButton] = [
        .aspectFill,
        .autoPlay,
        .playPreviousItem,
        .playNextItem,
    ]

    static let defaultMenuActionButtons: [VideoPlayerActionButton] = [
        .audio,
        .subtitles,
        .playbackSpeed,
    ]
}
