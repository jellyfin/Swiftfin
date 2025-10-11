//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

/// A protocol for items to conform to if they may be present within a library.
///
/// Similar to `Identifiable`, but `unwrappedIDHashOrZero` is an `Int`: the hash of the underlying `id`
/// value if it is not optional, or if it is optional it must return the hash of the wrapped value,
/// or 0 otherwise:
///
///     struct Item: LibraryIdentifiable {
///         var id: String? { "id" }
///
///         var unwrappedIDHashOrZero: Int {
///             // Gets the `hashValue` of the `String.hashValue`, not `Optional.hashValue`.
///             id?.hashValue ?? 0
///         }
///     }
///
/// This is necessary because if the `ID` is optional, then `Optional.hashValue` will be used instead
/// and result in differing hashes.
///
/// This also helps if items already conform to `Identifiable`, but has an optionally-typed `id`.
protocol LibraryIdentifiable: Identifiable {

    var unwrappedIDHashOrZero: Int { get }
}
