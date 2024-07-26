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
    @Default(.Customization.Library.displayType)
    private var libraryViewType

    @Default(.Customization.Library.cinematicBackground)
    private var cinematicBackground
    @Default(.Customization.Library.randomImage)
    private var libraryRandomImage
    @Default(.Customization.Library.showFavorites)
    private var showFavorites
    @Default(.Customization.showRecentlyAdded)
    private var showRecentlyAdded

    @Default(.Customization.Home.homeLabels)
    private var homeLabels
    @Default(.Customization.Home.homeSection1)
    private var homeSection1
    @Default(.Customization.Home.homeSection2)
    private var homeSection2
    @Default(.Customization.Home.homeSection3)
    private var homeSection3
    @Default(.Customization.Home.homeSection4)
    private var homeSection4
    @Default(.Customization.Home.homeSection5)
    private var homeSection5
    @Default(.Customization.Home.homeSection6)
    private var homeSection6

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

                    ChevronButton("Indicators")
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

                    Toggle("Show Recently Added", isOn: $showRecentlyAdded)

                } header: {
                    L10n.library.text
                }

                Section {

                    Toggle("Show Section labels", isOn: $homeLabels)

                    InlineEnumToggle(title: "Section 1", selection: $homeSection1)

                    InlineEnumToggle(title: "Section 2", selection: $homeSection2)

                    InlineEnumToggle(title: "Section 3", selection: $homeSection3)

                    InlineEnumToggle(title: "Section 4", selection: $homeSection4)

                    InlineEnumToggle(title: "Section 5", selection: $homeSection5)

                    InlineEnumToggle(title: "Section 6", selection: $homeSection6)

                } header: {
                    L10n.home.text
                } footer: {
                    Text("An app restart is required to update sections")
                }
            }
            .withDescriptionTopPadding()
            .navigationTitle(L10n.customize)
    }
}
