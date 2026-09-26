//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@OptionSet<Int>
struct TrailerSelection: CaseIterable, Displayable, Hashable, Storable {

    private enum Options: Int {
        case local
        case external
        case none
    }

    static var all: Self {
        [.local, .external]
    }

    static var allCases: [Self] {
        [.all, .local, .external, .none]
    }

    var displayTitle: String {
        switch self {
        case .all:
            L10n.all
        case .local:
            L10n.local
        case .external:
            L10n.external
        case .none:
            L10n.none
        default:
            L10n.unknown
        }
    }
}
