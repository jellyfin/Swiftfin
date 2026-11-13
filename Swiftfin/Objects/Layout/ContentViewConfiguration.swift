//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ContentViewConfiguration: Codable, Hashable, Identifiable, Displayable, SystemImageable {

    let id: String
    var name: String
    var icon: String
    var groups: [ContentGroupConfiguration]

    init(
        id: String = UUID().uuidString,
        name: String = "",
        icon: String = "rectangle.3.group",
        groups: [ContentGroupConfiguration] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.groups = groups
    }

    var displayTitle: String {
        name.nilIfEmpty ?? L10n.userView
    }

    var systemImage: String {
        icon
    }

    var hasValidName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
