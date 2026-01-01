//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum LoginFailurePolicy: Int, Displayable, CaseIterable {

    case unlimited = -1
    case userDefault = 0
    case custom = 1 // Default to 1

    var displayTitle: String {
        switch self {
        case .unlimited:
            return L10n.unlimited
        case .userDefault:
            return L10n.default
        case .custom:
            return L10n.custom
        }
    }
}
