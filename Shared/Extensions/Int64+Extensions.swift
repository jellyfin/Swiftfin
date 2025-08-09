//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Int64 {
    func toReadableFileSize() -> String {
        if self < 1024 {
            return "\(self) B"
        }
        let suffixes = ["B", "KB", "MB", "GB", "TB"]
        var i = 0
        var d = Double(self)
        while d >= 1024 && i < suffixes.count - 1 {
            d /= 1024
            i += 1
        }
        return String(format: "%.1f %@", d, suffixes[i])
    }
}
