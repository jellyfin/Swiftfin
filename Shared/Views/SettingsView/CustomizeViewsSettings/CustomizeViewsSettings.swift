//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CustomizeViewsSettings: View {

    @Default(.Customization.Search.enabledDrawerFilters)
    private var searchEnabledDrawerFilters

    #if os(tvOS)
    @Default(.Customization.tabBarPlacement)
    private var tabBarPlacement
    #endif

    @Router
    private var router

    var body: some View {
        Form(systemImage: "gear") {

            #if os(tvOS)
            Section(L10n.tabBar) {
                ListRowMenu(L10n.layout, selection: $tabBarPlacement)
            }
            #endif

            Section {
                ChevronButton(L10n.search) {
                    router.route(to: .itemFilterDrawerSelector(selection: $searchEnabledDrawerFilters))
                }

            } header: {
                Text(L10n.filters)
            }

            ChevronButton(L10n.items) {
                router.route(to: .itemSettings)
            }

            ChevronButton(L10n.libraries) {
                router.route(to: .librarySettings)
            }

            ChevronButton(L10n.posters) {
                router.route(to: .posterSettings)
            }

            HomeSection()
        }
        .navigationTitle(L10n.customize)
    }
}
