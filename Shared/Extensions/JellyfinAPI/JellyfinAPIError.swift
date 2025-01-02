//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: rename to `ErrorMessage` and remove other implementation

/// A basic error that holds a message, useful for debugging.
///
/// - Important: Only really use for debugging. For practical errors,
///              statically define errors for each domain/context.
struct JellyfinAPIError: LocalizedError, Hashable {

    private let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
