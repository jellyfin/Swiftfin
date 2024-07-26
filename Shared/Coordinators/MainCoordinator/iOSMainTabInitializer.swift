//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

struct MainTabInitializer {

    @Default(.Customization.Home.homeSections)
    var homeSections

    func create() -> TabChild {
        var sections: [AnyKeyPath] = []

        for mainTabType in homeSections {
            if let keyPath = mainTabType.keyPath {
                sections.append(keyPath)
            }
        }

        let nonNilSections = sections

        // Make sure the user doesn't remove Home because there would be no way for them to undo it. If they do have Home, respect
        // where they positioned it.
        if !nonNilSections.contains(\MainTabCoordinator.home) {
            let allSections = nonNilSections + [\MainTabCoordinator.home]
            return TabChild(startingItems: allSections)
        }
        return TabChild(startingItems: nonNilSections)
    }
}
