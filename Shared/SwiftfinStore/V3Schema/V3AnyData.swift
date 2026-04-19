//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation

extension SwiftfinStore.V3 {

    /// Used to store arbitrary data with a `name` and `ownerID`.
    ///
    /// Essentially just a bag-of-bytes model like UserDefaults, but for
    /// storing larger objects or arbitrary collection elements.
    ///
    /// Relationships generally take the form below, where `ownerID` is like
    /// an object, `field`s are property names, and `key`s are values within
    /// the `field`. An instance where `field == key` is like a single-value
    /// property while a `field` with many `keys` is like a dictionary.
    ///
    /// ownerID
    /// - field
    ///   - key(s)
    /// - field
    ///   - key(s)
    ///
    /// This can be useful to not require migrations on model objects for new
    /// "properties".
    final class AnyData: CoreStoreObject {

        @Field.Stored("data")
        var data: Data?

        @Field.Stored("ownerID")
        var ownerID: String = ""

        @Field.Stored("field")
        var field: String = ""

        @Field.Stored("key")
        var key: String = ""
    }
}
