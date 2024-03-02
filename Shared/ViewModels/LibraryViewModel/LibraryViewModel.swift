//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import OrderedCollections

class LibraryViewModel<Element: Poster>: ViewModel {

    @Published
    final var items: OrderedSet<Element>

    final var parent: (any LibraryParent)?

    init(_ data: some Collection<Element>, parent: (any LibraryParent)?) {
        self.items = OrderedSet(data)
        self.parent = parent
    }

    func getRandomItem() async throws -> Element? {
        items.randomElement()
    }
}
