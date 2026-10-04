//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum VideoPlayerActionButton: String, CaseIterable, Displayable, Equatable, Identifiable, Storable, SystemImageable {

    case aspectFill
    case audio
    case audioOffset
    case autoPlay
    case pictureInPicture
    case playbackSpeed
    case playbackSettings
    case playNextItem
    case playPreviousItem
    case subtitles
    #if os(iOS)
    case gestureLock
    #endif
    case subtitleOffset

    var displayTitle: String {
        switch self {
        case .aspectFill:
            L10n.aspectFill
        case .audio:
            L10n.audio
        case .audioOffset:
            L10n.audioOffset
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
        case .subtitles:
            L10n.subtitles
        #if os(iOS)
        case .gestureLock:
            L10n.gestureLock
        #endif
        case .subtitleOffset:
            L10n.subtitleOffset
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
        case .audioOffset: "waveform.path"
        case .autoPlay: "play.fill"
        case .pictureInPicture: "pip.enter"
        case .playbackSpeed: "speedometer"
        case .playbackSettings: "tv"
        case .playNextItem: "forward.end.fill"
        case .playPreviousItem: "backward.end.fill"
        case .subtitles: "captions.bubble.fill"
        case .subtitleOffset: "textformat.abc"
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
        let usesLiquidGlassSymbols = if #available(iOS 26.0, *) {
            true
        } else {
            false
        }

        return switch self {
        case .aspectFill: "arrow.up.left.and.arrow.down.right"
        case .audio: "speaker.wave.2.fill"
        case .audioOffset: "waveform.path"
        case .autoPlay: usesLiquidGlassSymbols ? "play.fill" : "play.circle.fill"
        case .gestureLock: usesLiquidGlassSymbols ? "lock.fill" : "lock.circle.fill"
        case .pictureInPicture: "pip.enter"
        case .playbackSpeed: "speedometer"
        case .playbackSettings: usesLiquidGlassSymbols ? "tv" : "tv.circle.fill"
        case .playNextItem: usesLiquidGlassSymbols ? "forward.end.fill" : "forward.end.circle.fill"
        case .playPreviousItem: usesLiquidGlassSymbols ? "backward.end.fill" : "backward.end.circle.fill"
        case .subtitles: "captions.bubble.fill"
        case .subtitleOffset: "textformat.abc"
        }
    }

    var secondarySystemImage: String {
        switch self {
        case .aspectFill: "arrow.down.right.and.arrow.up.left"
        case .audio: "speaker.wave.2"
        case .autoPlay:
            if #available(iOS 26.0, *) {
                "stop"
            } else {
                "stop.circle"
            }
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
    ]

    static let defaultMenuActionButtons: [VideoPlayerActionButton] = [
        .audio,
        .audioOffset,
        .subtitles,
        .subtitleOffset,
        .playbackSpeed,
        .pictureInPicture,
        .playbackSettings,
    ]
}
