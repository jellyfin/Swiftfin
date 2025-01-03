//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

extension CustomizeViewsSettings {

    struct LibrarySection: View {

        @Default(.Customization.Library.showFavorites)
        private var showFavorites
        @Default(.Customization.Library.randomImage)
        private var libraryRandomImage

        @Default(.Customization.Library.posterType)
        private var libraryPosterType
        @Default(.Customization.Library.displayType)
        private var libraryDisplayType
        @Default(.Customization.Library.listColumnCount)
        private var listColumnCount

        @Default(.Customization.Library.rememberLayout)
        private var rememberLibraryLayout
        @Default(.Customization.Library.rememberSort)
        private var rememberLibrarySort

        var body: some View {

            Section {

                // MARK: Media - Show Favorites

                Toggle(L10n.favorites.localizedCapitalized, isOn: $showFavorites)

                // MARK: Media - User Random Library Images

                Toggle(L10n.randomImage.localizedCapitalized, isOn: $libraryRandomImage)
            } header: {
                Text(L10n.media)
            } footer: {
                Text(L10n.mediaSettingsDescription)
            }

            Section {

                // MARK: Libary - Poster Type

                CaseIterablePicker(L10n.posters.localizedCapitalized, selection: $libraryPosterType)

                // MARK: Libary - Poster Layout

                CaseIterablePicker(L10n.layout.localizedCapitalized, selection: $libraryDisplayType)

                if libraryDisplayType == .list, UIDevice.isPad {

                    // MARK: Libary Rows - Row Count

                    BasicStepper(
                        title: L10n.columns.localizedCapitalized,
                        value: $listColumnCount,
                        range: 1 ... 4,
                        step: 1
                    )
                }
            } header: {
                Text(L10n.library)
            }

            Section {

                // MARK: Libary - Remember Last Sort

                Toggle(L10n.rememberSorting.localizedCapitalized, isOn: $rememberLibrarySort)

                // MARK: Libary - Remember Last Layout

                Toggle(L10n.rememberLayout.localizedCapitalized, isOn: $rememberLibraryLayout)
            } footer: {
                Text(L10n.rememberPreferencesPerLibrary)
            }
        }
    }
}
