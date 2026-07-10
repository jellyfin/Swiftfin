//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct PosterIndicator: OptionSet, Storable {

    let rawValue: Int

    static let favorited = Self(rawValue: 1 << 0)
    static let played = Self(rawValue: 1 << 1)
    static let progress = Self(rawValue: 1 << 2)
    static let unplayed = Self(rawValue: 1 << 3)

    static var all: Self {
        [.favorited, .played, .progress, .unplayed]
    }
}
