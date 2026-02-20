//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    #if os(iOS)
    static let aboutApp = NavigationRoute(
        id: "about-app"
    ) {
        AboutAppView()
    }

    static func appIconSelector(viewModel: SettingsViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "app-icon-selector"
        ) {
            AppIconSelectorView(viewModel: viewModel)
        }
    }
    #endif

    static let appSettings = NavigationRoute(
        id: "app-settings",
        style: .sheet
    ) {
        AppSettingsView()
    }

    #if os(tvOS)
    static let hourPicker = NavigationRoute(
        id: "hour-picker",
        style: .fullscreen
    ) {
        ZStack {
            BlurView()
                .ignoresSafeArea()

            HourMinutePicker()
        }
    }
    #endif
}
