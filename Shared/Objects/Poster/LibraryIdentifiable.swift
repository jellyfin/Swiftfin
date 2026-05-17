//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// A protocol for items to conform to if they may be present within a library.
///
/// Similar to `Identifiable`, but `unwrappedIDHashOrZero` is an `Int`: the hash
/// of the underlying `id` value if it exists, or 0 otherwise. This avoids
/// unstable IDs when the item's `ID` is optional.
protocol LibraryIdentifiable: Identifiable {

    var unwrappedIDHashOrZero: Int { get }
}
