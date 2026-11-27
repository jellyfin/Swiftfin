//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CustomizeSettingsView: View {

    #if os(tvOS)
    @Default(.Customization.Search.enabledDrawerFilters)
    private var searchEnabledDrawerFilters
    @Default(.Customization.tabBarPlacement)
    private var tabBarPlacement
    #endif

    @Router
    private var router

    @ContentBuilder
    var body: some View {
        Form(systemImage: "gear") {
            #if os(tvOS)
            Section(L10n.tabBar) {
                ListRowMenu(L10n.layout, selection: $tabBarPlacement)
            }
            Section {
                ChevronButton(L10n.search) {
                    router.route(to: .itemFilterDrawerSelector(selection: $searchEnabledDrawerFilters))
                }

            } header: {
                Text(L10n.filters)
            }
            #endif

            ChevronButton(L10n.items) {
                router.route(to: .itemSettings)
            }

            #if os(iOS)
            ChevronButton(L10n.layout) {
                router.route(to: .layoutSettings)
            }
            #endif

            ChevronButton(L10n.libraries) {
                router.route(to: .librarySettings)
            }

            ChevronButton(L10n.posters) {
                router.route(to: .posterSettings)
            }

            ChevronButton(L10n.videoPlayer) {
                router.route(to: .videoPlayerSettings)
            }

            #if os(tvOS)
            HomeSection()
            #endif
        }
        .navigationTitle(L10n.advanced)
    }
}
