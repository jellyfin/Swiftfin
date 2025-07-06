//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

// MARK: - Debug Methods for Testing Download Indicator

extension DownloadManager {

    /// Returns the count of active downloads for the floating indicator
    var activeDownloadCount: Int {
        downloads.filter { task in
            switch task.state {
            case .ready, .downloading:
                return true
            default:
                return false
            }
        }.count
    }

    /// Returns whether there are any active downloads
    var hasActiveDownloads: Bool {
        activeDownloadCount > 0
    }
}
