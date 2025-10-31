//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct MenuContentGroup: Identifiable, Equatable {

    let id: String
    let content: AnyView

    init(
        id: String = UUID().uuidString,
        @ViewBuilder content: () -> some View
    ) {
        self.id = id
        self.content = AnyView(content())
    }

    static func == (lhs: MenuContentGroup, rhs: MenuContentGroup) -> Bool {
        lhs.id == rhs.id
    }
}

struct MenuContentKey: PreferenceKey {

    static var defaultValue: [MenuContentGroup] = []

    static func reduce(value: inout [MenuContentGroup], nextValue: () -> [MenuContentGroup]) {
        value.append(contentsOf: nextValue())
    }
}
