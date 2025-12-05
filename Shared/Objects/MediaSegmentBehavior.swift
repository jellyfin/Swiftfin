//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

enum MediaSegmentBehavior: String, CaseIterable, Identifiable, Displayable {

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
