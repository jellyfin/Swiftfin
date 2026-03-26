//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ItemFields {

    /// The minimum cases to use when retrieving an item or items
    /// for basic presentation. Depending on the context, using
    /// more fields and including user data may also be necessary.
    static let MinimumFields: [ItemFields] = [
        .overview,
        .parentID,
        .taglines,
    ]

    /// Fields for detail pages that need media source information
    /// (e.g. video codec, resolution, multiple versions).
    static let DetailFields: [ItemFields] = MinimumFields + [
        .mediaSources,
    ]
}

extension [ItemFields] {

    static var MinimumFields: Self {
        ItemFields.MinimumFields
    }

    static var DetailFields: Self {
        ItemFields.DetailFields
    }
}
