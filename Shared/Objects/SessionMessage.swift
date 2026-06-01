//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct SessionMessage: Hashable {

    let header: String?
    let text: String
    let timeoutMs: Int?

    var displayText: String {
        if let header, header.isNotEmpty {
            "\(header)\n\(text)"
        } else {
            text
        }
    }

    var displayDuration: TimeInterval {
        guard let timeoutMs else {
            return 5
        }

        return min(max(Double(timeoutMs) / 1000, 1), 60)
    }
}
