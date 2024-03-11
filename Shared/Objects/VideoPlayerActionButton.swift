//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum VideoPlayerActionButton: String, CaseIterable, Defaults.Serializable, Displayable, Identifiable {

    case advanced
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
        case .advanced:
            return "Advanced"
        case .aspectFill:
            return "Aspect Fill"
        case .audio:
            return "Audio"
        case .autoPlay:
            return "Auto Play"
        case .chapters:
            return "Chapters"
        case .playbackSpeed:
            return "Playback Speed"
        case .playNextItem:
            return "Play Next Item"
        case .playPreviousItem:
            return "Play Previous Item"
        case .subtitles:
            return "Subtitles"
        }
    }

    var id: String {
        rawValue
    }

    var settingsSystemImage: String {
        switch self {
        case .advanced:
            return "gearshape.fill"
        case .aspectFill:
            return "arrow.up.left.and.arrow.down.right"
        case .audio:
            return "speaker.wave.2"
        case .autoPlay:
            return "play.circle.fill"
        case .chapters:
            return "list.bullet.circle"
        case .playbackSpeed:
            return "speedometer"
        case .playNextItem:
            return "chevron.right.circle"
        case .playPreviousItem:
            return "chevron.left.circle"
        case .subtitles:
            return "captions.bubble"
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
        .chapters,
        .advanced,
    ]
}
