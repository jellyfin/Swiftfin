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
    struct CustomizeLibrarySection: View {
        @Default(.Customization.Library.cinematicBackground)
        private var cinematicBackground
        @Default(.Customization.Library.randomImage)
        private var libraryRandomImage
        @Default(.Customization.Library.showFavorites)
        private var showFavorites
        @Default(.Customization.showRecentlyAdded)
        private var showRecentlyAdded

        @Default(.Customization.Library.displayType)
        private var libraryDisplayType
        @Default(.Customization.Library.posterType)
        private var libraryPosterType
        @Default(.Customization.Library.listColumnCount)
        private var listColumnCount

        @Default(.Customization.Library.rememberLayout)
        private var rememberLibraryLayout
        @Default(.Customization.Library.rememberSort)
        private var rememberLibrarySort

        var body: some View {
            Section {
                Toggle(L10n.cinematicBackground, isOn: $cinematicBackground)

                Toggle(L10n.randomImage, isOn: $libraryRandomImage)

                Toggle(L10n.showFavorites, isOn: $showFavorites)

                Toggle(L10n.showRecentlyAdded, isOn: $showRecentlyAdded)
            } header: {
                L10n.library.text
            } footer: {
                // L10n.libraryDescription.text
            }

            Section {
                CaseIterablePicker(L10n.library, selection: $libraryDisplayType)

                CaseIterablePicker(L10n.posters, selection: $libraryPosterType)

                if libraryDisplayType == .list, UIDevice.isPad {
                    BasicStepper(
                        title: "Columns",
                        value: $listColumnCount,
                        range: 1 ... 4,
                        step: 1
                    )
                }
            } footer: {
                Text("Customize The library layouts") // L10n.libraryDescription.text
            }

            Section {
                Toggle("Remember layout", isOn: $rememberLibraryLayout)
            } footer: {
                Text("Remember layout for individual libraries")
            }

            Section {
                Toggle("Remember sorting", isOn: $rememberLibrarySort)
            } footer: {
                Text("Remember sorting for individual libraries")
            }
        }
    }
}
