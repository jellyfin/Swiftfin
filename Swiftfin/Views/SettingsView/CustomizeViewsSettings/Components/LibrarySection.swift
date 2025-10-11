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

    struct LibrarySection: View {

        @Default(.Customization.Library.displayType)
        private var libraryDisplayType
        @Default(.Customization.Library.posterType)
        private var libraryPosterType
        @Default(.Customization.Library.listColumnCount)
        private var listColumnCount

        @Default(.Customization.Library.letterPickerEnabled)
        private var letterPickerEnabled
        @Default(.Customization.Library.letterPickerOrientation)
        private var letterPickerOrientation

        @Default(.Customization.Library.rememberLayout)
        private var rememberLibraryLayout
        @Default(.Customization.Library.rememberSort)
        private var rememberLibrarySort

        var body: some View {
            Form {
                Section(L10n.layout) {
                    CaseIterablePicker(L10n.layout, selection: $libraryDisplayType)

                    CaseIterablePicker(L10n.posters, selection: $libraryPosterType)

                    if libraryDisplayType == .list, UIDevice.isPad {
                        BasicStepper(
                            L10n.columns,
                            value: $listColumnCount,
                            range: 1 ... 4,
                            step: 1
                        )
                    }
                }

                Section {
                    Toggle(L10n.rememberLayout, isOn: $rememberLibraryLayout)
                } footer: {
                    Text(L10n.rememberLayoutFooter)
                }

                Section(L10n.letterPicker) {
                    Toggle(L10n.letterPicker, isOn: $letterPickerEnabled)

                    if letterPickerEnabled {
                        CaseIterablePicker(
                            L10n.orientation,
                            selection: $letterPickerOrientation
                        )
                    }
                }

                Section {
                    Toggle(L10n.rememberSorting, isOn: $rememberLibrarySort)
                } footer: {
                    Text(L10n.rememberSortingFooter)
                }
            }
            .navigationTitle(L10n.libraries)
        }
    }
}
