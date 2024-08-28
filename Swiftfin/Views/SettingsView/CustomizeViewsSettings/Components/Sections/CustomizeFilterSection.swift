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
    struct CustomizeFilterSection: View {
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
            Section {
                Toggle(L10n.letterPicker, isOn: $letterPickerEnabled)

                if letterPickerEnabled {
                    CaseIterablePicker(
                        L10n.orientation,
                        selection: $letterPickerOrientation
                    )
                }

                ChevronButton(L10n.library)
                    .onSelect {
                        router.route(to: \.itemFilterDrawerSelector, $libraryEnabledDrawerFilters)
                    }

                ChevronButton(L10n.search)
                    .onSelect {
                        router.route(to: \.itemFilterDrawerSelector, $searchEnabledDrawerFilters)
                    }

            } header: {
                L10n.filters.text
            } footer: {
                L10n.filters.text
            }
        }
    }
}
