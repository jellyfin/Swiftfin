//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TrailerSelection: OptionSet, CaseIterable, Displayable, Hashable, Storable {

    let rawValue: Int

    static let local = Self(rawValue: 1 << 0)
    static let external = Self(rawValue: 1 << 1)
    static let none = Self(rawValue: 1 << 2)
    static var all: Self {
        [.local, .external]
    }

    static var allCases: [Self] {
        [.none, .local, .external]
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
