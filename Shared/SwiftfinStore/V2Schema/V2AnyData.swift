//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Defaults
import Factory
import Foundation
import SwiftUI

extension SwiftfinStore.V2 {

    /// Used to store arbitrary data with a `name` and `ownerID`.
    ///
    /// Essentially just a bag-of-bytes model like UserDefaults, but for
    /// storing larger objects or arbitrary collection elements.
    ///
    /// Relationships generally take the form below, where `ownerID` is like
    /// an object, `domain`s are property names, and `key`s are values within
    /// the `domain`. An instance where `domain == key` is like a single-value
    /// property while a `domain` with many `keys` is like a dictionary.
    ///
    /// ownerID
    /// - domain
    ///   - key(s)
    /// - domain
    ///   - key(s)
    ///
    /// This can be useful to not require migrations on model objects for new
    /// "properties".
    final class AnyData: CoreStoreObject {

        @Field.Stored("data")
        var data: Data?

        @Field.Stored("domain")
        var domain: String = ""

        @Field.Stored("key")
        var key: String = ""

        @Field.Stored("ownerID")
        var ownerID: String = ""
    }
}
