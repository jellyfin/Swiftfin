//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct LiveTVGroupConfiguration: Codable, Hashable {

    var element: LiveTVElement
    var poster: PosterGroupSettings

    init(
        element: LiveTVElement = .onNow,
        poster: PosterGroupSettings = .liveTV
    ) {
        self.element = element
        self.poster = poster
    }
}
