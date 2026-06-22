//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension CustomizeViewsSettings {

    struct LibrarySection: View {

        @Default(.Customization.Library.showFavorites)
        private var showFavorites
        @Default(.Customization.Library.enabledDrawerFilters)
        private var libraryEnabledDrawerFilters
        @Default(.Customization.Library.randomImage)
        private var libraryRandomImage
        @Default(.Customization.Library.style)
        private var libraryStyle
        @Default(.Customization.Library.letterPickerOrientation)
        private var letterPickerOrientation

        @Default(.Customization.Library.rememberLayout)
        private var rememberLibraryLayout
        @Default(.Customization.Library.rememberSort)
        private var rememberLibrarySort

        @Router
        private var router

        var body: some View {
            Form {

                Section {
                    Toggle(L10n.favorites, isOn: $showFavorites)

                    Toggle(L10n.randomImage, isOn: $libraryRandomImage)
                } footer: {}

                Section(L10n.filters) {
                    ChevronButton(L10n.filters) {
                        router.route(
                            to: .itemFilterDrawerSelector(selection: $libraryEnabledDrawerFilters)
                        )
                    }
                }

                Section {
                    Toggle(L10n.rememberSorting, isOn: $rememberLibrarySort)
                }

                Section(L10n.layout) {
                    Picker(L10n.layout, selection: $libraryStyle.displayType)

                    Picker(L10n.posters, selection: $libraryStyle.posterDisplayType)

                    if libraryStyle.displayType == .list, !UIDevice.isPhone {
                        Stepper(L10n.columns, value: $libraryStyle.listColumnCount, in: 1 ... 4, step: 1) {
                            LabeledContent(L10n.columns, value: libraryStyle.listColumnCount.description)
                        }
                    }
                }

                Section {
                    Toggle(L10n.rememberLayout, isOn: $rememberLibraryLayout)
                }

                Section(L10n.letterPicker) {
                    Picker(L10n.letterPicker, selection: $letterPickerOrientation)
                }
            }
            .navigationTitle(L10n.libraries)
        }
    }
}
