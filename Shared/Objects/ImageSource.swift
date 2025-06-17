//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Represents an image source along with a blur hash
/// to be used as a placeholder.
struct ImageSource: Hashable {

    let url: URL?
    let blurHash: String?

    init(
        url: URL? = nil,
        blurHash: String? = nil
    ) {
        self.url = url
        self.blurHash = blurHash
    }
}
