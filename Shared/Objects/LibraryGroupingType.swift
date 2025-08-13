//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

enum LibraryGroupingType: String, CaseIterable, Displayable, Storable, SystemImageable {

    case group
    case ungrouped

    // TODO: localize
    var displayTitle: String {
        switch self {
        case .group:
            "Group"
        case .ungrouped:
            "Ungroup"
        }
    }

    var systemImage: String {
        switch self {
        case .group:
            "rectangle.3.group.fill"
        case .ungrouped:
            "rectangle.3.group"
        }
    }
}
