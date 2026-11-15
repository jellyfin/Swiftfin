//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreSpotlight
import Foundation

enum SwiftfinSpotlight {

    @concurrent
    static func addSwiftfinToSpotlight() async {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.application)
        attributeSet.title = L10n.jellyfin

        let searchableItem = CSSearchableItem(
            uniqueIdentifier: "org.jellyfin.swiftfin",
            domainIdentifier: nil,
            attributeSet: attributeSet
        )

        let mainIndex = CSSearchableIndex(name: "SwiftfinAppIndex")
        try? await mainIndex.indexSearchableItems([searchableItem])
    }
}
