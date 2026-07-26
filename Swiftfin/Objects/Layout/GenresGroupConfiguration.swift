//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct GenresGroupConfiguration: Codable, Hashable {

    var parent: LibraryReference?
    var searchTerm: String?
    var itemTypes: [BaseItemKind]

    init(
        parent: LibraryReference? = nil,
        searchTerm: String? = nil,
        itemTypes: [BaseItemKind] = []
    ) {
        self.parent = parent
        self.searchTerm = searchTerm.nilIfEmpty
        self.itemTypes = itemTypes
    }
}
