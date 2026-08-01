//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum ImageQuality: CaseIterable, Displayable, Hashable, Storable {

    case quality
    case performance

    var rawValue: Int? {
        switch self {
        case .quality:
            nil
        case .performance:
            90
        }
    }

    var displayTitle: String {
        switch self {
        case .quality:
            L10n.quality
        case .performance:
            L10n.performance
        }
    }
}
