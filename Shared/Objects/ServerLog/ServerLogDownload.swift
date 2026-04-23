//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// A downloaded server log's on-device location, server location, and parsed content (if available).
struct ServerLogDownload: Hashable {

    let url: URL
    let webURL: URL
    let content: ServerLogContent?
}
