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

    @Default(.Customization.shouldShowMissingSeasons)
    private var shouldShowMissingSeasons
    @Default(.Customization.shouldShowMissingEpisodes)
    private var shouldShowMissingEpisodes

    @Default(.Customization.showPosterLabels)
    private var showPosterLabels
    @Default(.Customization.nextUpPosterType)
    private var nextUpPosterType
    @Default(.Customization.recentlyAddedPosterType)
    private var recentlyAddedPosterType
    @Default(.Customization.latestInLibraryPosterType)
    private var latestInLibraryPosterType
    @Default(.Customization.similarPosterType)
    private var similarPosterType
    @Default(.Customization.searchPosterType)
    private var searchPosterType
    @Default(.Customization.Library.displayType)
    private var libraryViewType

    @Router
    private var router

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "gearshape")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section(L10n.missingItems) {

                    Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)

                    Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
                }

                Section(L10n.posters) {

                    ChevronButton(L10n.indicators) {
                        router.route(to: .indicatorSettings)
                    }

                    Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                    ListRowMenu(L10n.next, selection: $nextUpPosterType)

                    ListRowMenu(L10n.recentlyAdded, selection: $recentlyAddedPosterType)

                    ListRowMenu(L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType)

                    ListRowMenu(L10n.recommended, selection: $similarPosterType)

                    ListRowMenu(L10n.search, selection: $searchPosterType)
                }

                LibrarySection()

                ItemSection()

                HomeSection()
            }
            .navigationTitle(L10n.customize)
    }
}
