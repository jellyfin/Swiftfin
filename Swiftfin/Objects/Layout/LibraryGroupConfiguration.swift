//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct LibraryGroupConfiguration: Codable, Hashable {

    var library: ItemReference?
    var filters: ItemFilterCollection
    var poster: PosterGroupSettings

    init(
        library: ItemReference? = nil,
        filters: ItemFilterCollection = .default,
        poster: PosterGroupSettings = .default
    ) {
        self.library = library
        self.filters = filters
        self.poster = poster
    }
}
