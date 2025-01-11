//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

// TODO: remove Chapters. Will be replaced as a media player supplement
enum VideoPlayerActionButton: String, CaseIterable, Displayable, Identifiable, Storable, SystemImageable {

    case aspectFill
    case audio
    case autoPlay
    case chapters
    case playbackSpeed
    case playNextItem
    case playPreviousItem
    case subtitles

    var displayTitle: String {
        switch self {
//        case .advanced:
//            return L10n.advanced
        case .aspectFill:
            return L10n.aspectFill
        case .audio:
            return L10n.audio
        case .autoPlay:
            return L10n.autoPlay
        case .chapters:
            return L10n.chapters
        case .playbackSpeed:
            return L10n.playbackSpeed
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
        case .audio: "speaker.wave.2"
        case .autoPlay: "play.circle.fill"
        case .chapters: "list.bullet"
        case .playbackSpeed: "speedometer"
        case .playNextItem: "chevron.right.circle"
        case .playPreviousItem: "chevron.left.circle"
        case .subtitles: "captions.bubble"
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
