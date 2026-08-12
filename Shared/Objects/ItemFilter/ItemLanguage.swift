//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ItemLanguage: Codable, Hashable, ItemFilter {

    let displayTitle: String
    let value: String

    init(displayTitle: String, value: String) {
        self.displayTitle = displayTitle
        self.value = value
    }

    init(from anyFilter: AnyItemFilter) {
        self.displayTitle = anyFilter.displayTitle
        self.value = anyFilter.value
    }

    init?(_ nameValuePair: NameValuePair) {
        guard let name = nameValuePair.name, let value = nameValuePair.value else { return nil }

        self.displayTitle = name
        self.value = value
    }
}
