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
            return L10n.unknown
        case .clip:
            return L10n.clip
        case .trailer:
            return L10n.trailer
        case .behindTheScenes:
            return L10n.behindTheScenes
        case .deletedScene:
            return L10n.deletedScene
        case .interview:
            return L10n.interview
        case .scene:
            return L10n.scene
        case .sample:
            return L10n.sample
        case .themeSong:
            return L10n.themeSong
        case .themeVideo:
            return L10n.themeVideo
        case .featurette:
            return L10n.featurette
        case .short:
            return L10n.short
        }
    }

    var isVideo: Bool {
        self != .themeSong
    }
}
