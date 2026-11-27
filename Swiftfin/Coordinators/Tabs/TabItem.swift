//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
struct TabItem: Displayable, @MainActor Identifiable, @MainActor Hashable {

    let id: String
    let displayTitle: String
    let systemImage: String
    let destination: TabDestination?
    let content: AnyView

    init(
        id: String,
        title: String,
        systemImage: String,
        destination: TabDestination? = nil,
        @ContentBuilder content: () -> some View
    ) {
        self.id = id
        self.displayTitle = title
        self.systemImage = systemImage
        self.destination = destination
        self.content = AnyView(content())
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
