//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Date {

    // MARK: - Return the Date at 00:00:00

    var dateOnly: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)

        if let dateOnly = calendar.date(from: components) {
            return dateOnly
        } else {
            return self
        }
    }
}
