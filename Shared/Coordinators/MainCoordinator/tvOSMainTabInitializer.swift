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

    @Default(.Customization.Home.homeSection1)
    var homeSection1
    @Default(.Customization.Home.homeSection2)
    var homeSection2
    @Default(.Customization.Home.homeSection3)
    var homeSection3
    @Default(.Customization.Home.homeSection4)
    var homeSection4
    @Default(.Customization.Home.homeSection5)
    var homeSection5
    @Default(.Customization.Home.homeSection6)
    var homeSection6

    func create() -> TabChild {
        let sections: [AnyKeyPath?] = [
            homeSection1.keyPath,
            homeSection2.keyPath,
            homeSection3.keyPath,
            homeSection4.keyPath,
            homeSection5.keyPath,
            homeSection6.keyPath,
        ]

        let nonNilSections = sections.compactMap { $0 }

        // Make sure the user doesn't remove settings because there would be no way for them to undo it. If they do have Settings, respect
        // where they positioned it.
        if !nonNilSections.contains(\MainTabCoordinator.settings) {
            let allSections = nonNilSections + [\MainTabCoordinator.settings]
            return TabChild(startingItems: allSections)
        }
        return TabChild(startingItems: nonNilSections)
    }
}
