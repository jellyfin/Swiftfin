//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ItemDescription: Identifiable {
    let id = UUID()
    let item: String
    let description: String

    // MARK: - Initializer

    init(_ item: String, description: String) {
        self.item = item
        self.description = description
    }
}
