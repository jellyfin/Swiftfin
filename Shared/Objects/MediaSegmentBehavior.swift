//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults

enum MediaSegmentBehavior: String, CaseIterable, Defaults.Serializable, Identifiable, Displayable {

    case off
    case ask
    case skip

    var id: String {
        self.rawValue
    }

    var displayTitle: String {
        switch self {
        case .ask:
            L10n.ask
        case .off:
            L10n.off
        case .skip:
            L10n.skip
        }
    }
}
