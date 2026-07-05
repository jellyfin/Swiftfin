//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct SupplementPosterButton<Item: Poster>: View {

    private let action: () -> Void
    private let item: Item

    init(
        item: Item,
        action: @escaping () -> Void
    ) {
        self.item = item
        self.action = action
    }

    var body: some View {
        #if os(tvOS)
        PosterButton(
            item: item,
            type: .landscape,
            action: action
        )
        #else
        PosterButton(
            item: item,
            type: .landscape,
            action: { _ in action() }
        )
        #endif
    }
}
