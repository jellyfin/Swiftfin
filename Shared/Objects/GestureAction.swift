//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

// TODO: split out into separate files under folder `GestureAction`

// Optional values aren't yet supported in Defaults
// https://github.com/sindresorhus/Defaults/issues/54

protocol GestureAction: CaseIterable, Codable, Defaults.Serializable, Displayable {}

enum LongPressAction: String, GestureAction {

    case none
    case gestureLock

    var displayTitle: String {
        switch self {
        case .none:
            return L10n.none
        case .gestureLock:
            return "Gesture Lock"
        }
    }
}

enum MultiTapAction: String, GestureAction {

    case none
    case jump

    var displayTitle: String {
        switch self {
        case .none:
            return L10n.none
        case .jump:
            return L10n.jump
        }
    }
}

enum DoubleTouchAction: String, GestureAction {

    case none
    case aspectFill
    case gestureLock
    case pausePlay

    var displayTitle: String {
        switch self {
        case .none:
            return L10n.none
        case .aspectFill:
            return L10n.aspectFill
        case .gestureLock:
            return "Gesture Lock"
        case .pausePlay:
            return L10n.playAndPause
        }
    }
}

enum PanAction: String, GestureAction {

    case none
    case audioffset
    case brightness
    case playbackSpeed
    case scrub
    case slowScrub
    case subtitleOffset
    case volume

    var displayTitle: String {
        switch self {
        case .none:
            return L10n.none
        case .audioffset:
            return L10n.audioOffset
        case .brightness:
            return "Brightness"
        case .playbackSpeed:
            return L10n.playbackSpeed
        case .scrub:
            return "Scrub"
        case .slowScrub:
            return "Slow Scrub"
        case .subtitleOffset:
            return L10n.subtitleOffset
        case .volume:
            return "Volume"
        }
    }
}

enum PinchAction: String, GestureAction {

    case none
    case aspectFill

    var displayTitle: String {
        switch self {
        case .none:
            return L10n.none
        case .aspectFill:
            return L10n.aspectFill
        }
    }
}

enum SwipeAction: String, GestureAction {

    case none
    case jump

    var displayTitle: String {
        switch self {
        case .none:
            return L10n.none
        case .jump:
            return L10n.jump
        }
    }
}
