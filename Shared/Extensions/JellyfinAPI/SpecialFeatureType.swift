//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension SpecialFeatureType: Displayable {

    // TODO: localize
    var displayTitle: String {
        switch self {
        case .unknown:
            return L10n.unknown
        case .clip:
            return "Clip"
        case .trailer:
            return "Trailer"
        case .behindTheScenes:
            return "Behind the Scenes"
        case .deletedScene:
            return "Deleted Scene"
        case .interview:
            return "Interview"
        case .scene:
            return "Scene"
        case .sample:
            return "Sample"
        case .themeSong:
            return "Theme Song"
        case .themeVideo:
            return "Theme Video"
        }
    }

    var isVideo: Bool {
        self != .themeSong
    }
}
