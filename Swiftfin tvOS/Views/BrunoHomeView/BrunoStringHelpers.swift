//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// Small string helpers for the Bruno Collections surfaces.
extension String {

    /// Whitespace-trimmed, lowercased — the normalization used for case-insensitive name matching
    /// of owner-authored collection names (e.g. excluding director collections from Boxed Sets).
    var trimmedLowercased: String {
        trimmingCharacters(in: .whitespaces).lowercased()
    }

    /// Drops a trailing " Collection" so a box-set title can render as two lines ("Indiana Jones"
    /// then "Collection"). Case-insensitive; trims; leaves titles that don't end in " Collection"
    /// untouched and never returns an empty string (a title that is exactly "Collection" is kept).
    var brunoStrippingCollectionSuffix: String {
        let trimmed = trimmingCharacters(in: .whitespaces)
        let suffix = " Collection"
        guard trimmed.count > suffix.count,
              trimmed.lowercased().hasSuffix(suffix.lowercased())
        else { return trimmed }
        return String(trimmed.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
    }
}
