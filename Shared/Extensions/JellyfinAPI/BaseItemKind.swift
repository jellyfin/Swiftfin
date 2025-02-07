//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension BaseItemKind: SupportedCaseIterable {

    /// The base supported cases for media navigation.
    /// This differs from media viewing, which may include
    /// `.episode`.
    ///
    /// These is the *base* supported cases and other objects
    /// like `LibararyParent` may have additional supported
    /// cases for querying a library.
    static var supportedCases: [BaseItemKind] {
        [.movie, .series, .boxSet]
    }
}

extension BaseItemKind: ItemFilter {

    // TODO: localize
    var displayTitle: String {
        rawValue
    }
}
