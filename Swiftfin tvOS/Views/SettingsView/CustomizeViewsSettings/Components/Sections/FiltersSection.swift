//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension CustomizeViewsSettings {

    struct FiltersSection: View {

        @EnvironmentObject
        private var router: CustomizeSettingsCoordinator.Router

        @Default(.Customization.Library.letterPickerEnabled)
        private var letterPickerEnabled
        @Default(.Customization.Library.letterPickerOrientation)
        private var letterPickerOrientation
        @Default(.Customization.Library.enabledDrawerFilters)
        private var libraryEnabledDrawerFilters
        @Default(.Customization.Search.enabledDrawerFilters)
        private var searchEnabledDrawerFilters

        var body: some View {
            Section(L10n.filters) {

                Toggle(L10n.letterPicker, isOn: $letterPickerEnabled)

                ChevronButton(L10n.library) {
                    router.route(to: \.itemFilterDrawerSelector, $libraryEnabledDrawerFilters)
                }

                ChevronButton(L10n.search) {
                    router.route(to: \.itemFilterDrawerSelector, $searchEnabledDrawerFilters)
                }
            }
        }
    }
}
