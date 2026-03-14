//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DayOfWeek {

    var displayTitle: String {
        let newLineRemoved = rawValue.replacingOccurrences(of: "\n", with: "")

        /// The enum is in English so validation must be done against a calendar in English
        let englishCalendar = DateFormatter()
        englishCalendar.locale = Locale(identifier: "en_US_POSIX")

        guard let index = englishCalendar.weekdaySymbols.firstIndex(of: newLineRemoved) else {
            return rawValue
                .localizedCapitalized
        }

        return Calendar.current
            .weekdaySymbols[index]
            .localizedCapitalized
    }
}
