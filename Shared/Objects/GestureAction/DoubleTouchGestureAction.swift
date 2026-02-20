//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum DoubleTouchGestureAction: String, GestureAction {

    case none
    case aspectFill
    case gestureLock
    case pausePlay

    var displayTitle: String {
        switch self {
        case .none:
            L10n.none
        case .aspectFill:
            L10n.aspectFill
        case .gestureLock:
            L10n.gestureLock
        case .pausePlay:
            L10n.playAndPause
        }
    }
}
