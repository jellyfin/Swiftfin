//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension LogFile {

    /// A downloaded log file's local & server location,and parsed content (if available).
    struct Download: Hashable {

        let url: URL
        let webURL: URL?
        let content: Content?
    }
}
