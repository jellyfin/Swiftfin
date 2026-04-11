//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension CountryInfo: Displayable {

    var displayTitle: String {
        if let twoLetterISORegionName, let name = Locale.current.localizedString(forRegionCode: twoLetterISORegionName) {
            return name
        }

        if let threeLetterISORegionName, let name = Locale.current.localizedString(forRegionCode: threeLetterISORegionName) {
            return name
        }

        return displayName ?? L10n.unknown
    }
}

extension CountryInfo: @retroactive Identifiable {
    public var id: Int {
        hashValue
    }
}
