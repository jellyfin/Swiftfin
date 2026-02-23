//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ExtraType: Displayable {

    var displayTitle: String {
        switch self {
        case .unknown:
            L10n.unknown
        case .clip:
            L10n.clip
        case .trailer:
            L10n.trailer
        case .behindTheScenes:
            L10n.behindTheScenes
        case .deletedScene:
            L10n.deletedScene
        case .interview:
            L10n.interview
        case .scene:
            L10n.scene
        case .sample:
            L10n.sample
        case .themeSong:
            L10n.themeSong
        case .themeVideo:
            L10n.themeVideo
        case .featurette:
            L10n.featurette
        case .short:
            L10n.short
        }
    }

    var isVideo: Bool {
        self != .themeSong
    }
}
