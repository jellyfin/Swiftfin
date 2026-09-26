//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@OptionSet<Int>
struct PosterIndicator: Hashable, Storable {

    private enum Options: Int {
        case favorited
        case played
        case progress
        case unplayed
    }

    static var all: Self {
        [.favorited, .played, .progress, .unplayed]
    }
}
