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
//    case audioOffset
    case autoPlay
    case pictureInPicture
    case playbackSpeed
//    case playbackQuality
    case playNextItem
    case playPreviousItem
//    case subtitleOffset
    case subtitles
    #if os(iOS)
    case airPlay
    case gestureLock
    #endif

    var displayTitle: String {
        switch self {
        #if os(iOS)
        case .airPlay:
            L10n.airPlay
        #endif
        case .aspectFill:
            L10n.aspectFill
        case .audio:
            L10n.audio
//        case .audioOffset:
//            L10n.audioOffset
        case .autoPlay:
            L10n.autoPlay
        #if os(iOS)
        case .gestureLock:
            L10n.gestureLock
        #endif
        case .pictureInPicture:
            L10n.pictureInPicture
        case .playbackSpeed:
            L10n.playbackSpeed
//        case .playbackQuality:
//            return L10n.playbackQuality
        case .playNextItem:
            L10n.playNextItem
        case .playPreviousItem:
            L10n.playPreviousItem
//        case .subtitleOffset:
//            L10n.subtitleOffset
        case .subtitles:
            L10n.subtitles
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
//        case .audioOffset: "waveform.circle"
        case .autoPlay: "play.fill"
        case .pictureInPicture: "pip.enter"
        case .playbackSpeed: "speedometer"
//        case .playbackQuality: "tv.circle"
        case .playNextItem: "forward.end.fill"
        case .playPreviousItem: "backward.end.fill"
//        case .subtitleOffset: "text.bubble"
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
        case .airPlay: "airplayvideo"
        case .aspectFill: "arrow.up.left.and.arrow.down.right"
        case .audio: "speaker.wave.2.fill"
//        case .audioOffset: "waveform.circle.fill"
        case .autoPlay: "play.circle.fill"
        case .gestureLock: "lock.circle.fill"
        case .pictureInPicture: "pip.enter"
        case .playbackSpeed: "speedometer"
//        case .playbackQuality: "tv.circle.fill"
        case .playNextItem: "forward.end.circle.fill"
        case .playPreviousItem: "backward.end.circle.fill"
//        case .subtitleOffset: "text.bubble.fill"
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

    /// Cases supported within a `Menu`
    static let supportedCases: [VideoPlayerActionButton] = {
        return allCases
        #if os(iOS)
            .subtracting([.airPlay])
        #endif
    }()

    static let defaultBarActionButtons: [VideoPlayerActionButton] = {
        var buttons: [VideoPlayerActionButton] = [
            .aspectFill,
            .autoPlay,
            .playPreviousItem,
            .playNextItem,
        ]

        #if os(iOS)
        buttons.append(.airPlay)
        #endif

        return buttons
    }()

    static let defaultMenuActionButtons: [VideoPlayerActionButton] = [
        .audio,
        .subtitles,
        .playbackSpeed,
        .pictureInPicture,
    ]
}
