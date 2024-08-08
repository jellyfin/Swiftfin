//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class CustomizeSettingsCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \CustomizeSettingsCoordinator.start)

    @Root
    var start = makeStart

    @Route(.modal)
    var indicatorSettings = makeIndicatorSettings

    func makeIndicatorSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            IndicatorSettingsView()
        }
    }

    @ViewBuilder
    func makeStart() -> some View {
        CustomizeViewsSettings()
    }
}
