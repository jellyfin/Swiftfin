//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum MultiTapGestureAction: String, GestureAction {

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
