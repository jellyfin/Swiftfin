//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import UIKit

struct ItemLetter: CaseIterable, Codable, ExpressibleByStringLiteral, Hashable, ItemFilter {

    let value: String

    var displayTitle: String {
        value
    }

    init(stringLiteral value: String) {
        self.value = value
    }

    init(from anyFilter: AnyItemFilter) {
        self.value = anyFilter.value
    }

    static var allCases: [ItemLetter] {
        UILocalizedIndexedCollation
            .current()
            .sectionTitles
            .subtracting(["#"])
            .prepending("#")
            .map(Self.init)
    }
}
