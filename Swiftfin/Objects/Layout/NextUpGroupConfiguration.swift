//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct NextUpGroupConfiguration: Codable, Hashable {

    static let defaultDays = 366

    var library: LibraryReference?
    var series: ItemReference?
    var enableRewatching: Bool
    var maxDays: Int?
    var poster: PosterGroupSettings

    init(
        library: LibraryReference? = nil,
        series: ItemReference? = nil,
        enableRewatching: Bool = false,
        maxDays: Int? = Self.defaultDays,
        poster: PosterGroupSettings = .default
    ) {
        self.library = series == nil ? library : nil
        self.series = series
        self.enableRewatching = enableRewatching
        self.maxDays = maxDays.flatMap { $0 > 0 ? $0 : nil }
        self.poster = poster
    }
}
