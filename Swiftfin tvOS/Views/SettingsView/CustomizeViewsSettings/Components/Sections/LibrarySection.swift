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

        @Default(.Customization.Library.randomImage)
        private var libraryRandomImage
        @Default(.Customization.Library.showFavorites)
        private var showFavorites

        @Default(.Customization.Library.cinematicBackground)
        private var cinematicBackground
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

        @Router
        private var router

        @State
        private var isPresentingNextUpDays = false

        var body: some View {
            Section(L10n.media) {

                Toggle(L10n.randomImage, isOn: $libraryRandomImage)

                Toggle(L10n.showFavorites, isOn: $showFavorites)
            }

            Section(L10n.library) {
                Toggle(L10n.cinematicBackground, isOn: $cinematicBackground)

                ListRowMenu(L10n.posters, selection: $libraryPosterType)

                ListRowMenu(L10n.library, selection: $libraryDisplayType)

                if libraryDisplayType == .list {
                    ChevronButton(
                        L10n.columns,
                        subtitle: listColumnCount.description
                    ) {
                        // TODO: Implement listColumnSettings route in new Router system
//                        router.route(to: .listColumnSettings(columnCount: $listColumnCount))
                    }
                }
            }

            Section {
                Toggle(L10n.rememberLayout, isOn: $rememberLibraryLayout)
            } footer: {
                Text(L10n.rememberLayoutFooter)
            }

            Section {
                Toggle(L10n.rememberSorting, isOn: $rememberLibrarySort)
            } footer: {
                Text(L10n.rememberSortingFooter)
            }
        }
    }
}
