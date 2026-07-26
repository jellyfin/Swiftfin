//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum PosterSize: String, CaseIterable, Codable, Hashable, Displayable {

    case extraSmall
    case small
    case medium

    var posterSize: PosterDisplayType.Size {
        switch self {
        case .extraSmall:
            .extraSmall
        case .small:
            .small
        case .medium:
            .medium
        }
    }

    var displayTitle: String {
        switch self {
        case .extraSmall:
            L10n.smallest
        case .small:
            L10n.regular
        case .medium:
            L10n.larger
        }
    }
}
