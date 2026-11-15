//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension LayoutSettingsView {

    struct SearchSection: View {

        @Default(.Customization.Search.enabledDrawerFilters)
        private var enabledDrawerFilters

        @Router
        private var router

        @ContentBuilder
        var body: some View {
            Section(L10n.search) {
                ChevronButton(L10n.filters) {
                    router.route(to: .itemFilterDrawerSelector(selection: $enabledDrawerFilters))
                }
            }
        }
    }
}
