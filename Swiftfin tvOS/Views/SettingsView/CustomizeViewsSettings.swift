//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
    @Default(.Customization.Library.viewType)
    private var libraryViewType

    @Default(.Customization.Library.cinematicBackground)
    private var cinematicBackground
    @Default(.Customization.Library.randomImage)
    private var libraryRandomImage
    @Default(.Customization.Library.showFavorites)
    private var showFavorites

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "gearshape")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section {

                    Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)

                    Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
                } header: {
                    L10n.missingItems.text
                }

                Section {

                    ChevronButton(title: "Indicators")
                        .onSelect {
                            router.route(to: \.indicatorSettings)
                        }

                    Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                    InlineEnumToggle(title: L10n.next, selection: $nextUpPosterType)

                    InlineEnumToggle(title: L10n.recentlyAdded, selection: $recentlyAddedPosterType)

                    InlineEnumToggle(title: L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType)

                    InlineEnumToggle(title: L10n.recommended, selection: $similarPosterType)

                    InlineEnumToggle(title: L10n.search, selection: $searchPosterType)

                    InlineEnumToggle(title: L10n.library, selection: $libraryViewType)

                } header: {
                    Text("Posters")
                }

                Section {

                    Toggle("Cinematic Background", isOn: $cinematicBackground)

                    Toggle("Random Image", isOn: $libraryRandomImage)

                    Toggle("Show Favorites", isOn: $showFavorites)
                } header: {
                    L10n.library.text
                }
            }
            .withDescriptionTopPadding()
            .navigationTitle(L10n.customize)
    }
}
