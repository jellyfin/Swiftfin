//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension CustomizeViewsSettings {

    struct FilterSection: View {

        @Default(.Customization.Library.letterPickerEnabled)
        private var letterPickerEnabled
        @Default(.Customization.Library.letterPickerOrientation)
        private var letterPickerOrientation
        @Default(.Customization.Library.enabledDrawerFilters)
        private var libraryEnabledDrawerFilters
        @Default(.Customization.Search.enabledDrawerFilters)
        private var searchEnabledDrawerFilters

        @EnvironmentObject
        private var router: SettingsCoordinator.Router

        var body: some View {

            Section(L10n.filters) {

                // MARK: Letter Picker Toggle

                Toggle(
                    L10n.letterPicker.localizedCapitalized,
                    isOn: $letterPickerEnabled
                )

                if letterPickerEnabled {

                    // MARK: Letter Picker Orientation

                    CaseIterablePicker(
                        L10n.orientation.localizedCapitalized,
                        selection: $letterPickerOrientation
                    )
                }

                // MARK: Library Filters

                ChevronButton(L10n.library)
                    .onSelect {
                        router.route(to: \.itemFilterDrawerSelector, $libraryEnabledDrawerFilters)
                    }

                // MARK: Search Filters

                ChevronButton(L10n.search)
                    .onSelect {
                        router.route(to: \.itemFilterDrawerSelector, $searchEnabledDrawerFilters)
                    }
            }
        }
    }
}
