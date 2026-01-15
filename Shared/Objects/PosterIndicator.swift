//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct PosterIndicator: OptionSet, Storable {

    let rawValue: Int

    static let favorited = PosterIndicator(rawValue: 1 << 0)
    static let played = PosterIndicator(rawValue: 1 << 1)
    static let progress = PosterIndicator(rawValue: 1 << 2)
    static let unplayed = PosterIndicator(rawValue: 1 << 3)
}
