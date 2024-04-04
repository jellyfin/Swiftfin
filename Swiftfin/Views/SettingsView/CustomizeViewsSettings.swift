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

    @Default(.Customization.itemViewType)
    private var itemViewType
    @Default(.Customization.CinematicItemViewType.usePrimaryImage)
    private var cinematicItemViewTypeUsePrimaryImage

    @Default(.hapticFeedback)
    private var hapticFeedback

    @Default(.Customization.shouldShowMissingSeasons)
    private var shouldShowMissingSeasons
    @Default(.Customization.shouldShowMissingEpisodes)
    private var shouldShowMissingEpisodes

    @Default(.Customization.Library.enabledDrawerFilters)
    private var libraryEnabledDrawerFilters
    @Default(.Customization.Search.enabledDrawerFilters)
    private var searchEnabledDrawerFilters

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
    @Default(.Customization.Library.listColumnCount)
    private var listColumnCount

    @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
    private var useSeriesLandscapeBackdrop

    @Default(.Customization.Library.showFavorites)
    private var showFavorites
    @Default(.Customization.Library.randomImage)
    private var libraryRandomImage

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    var body: some View {
        List {

            if UIDevice.isPhone {
                Section {
                    CaseIterablePicker(title: L10n.items, selection: $itemViewType)
                }

                if itemViewType == .cinematic {
                    Section {
                        Toggle(L10n.usePrimaryImage, isOn: $cinematicItemViewTypeUsePrimaryImage)
                    } footer: {
                        L10n.usePrimaryImageDescription.text
                    }
                }

                Toggle(L10n.hapticFeedback, isOn: $hapticFeedback)
            }

            Section {

                Toggle(L10n.favorites, isOn: $showFavorites)
                Toggle(L10n.randomImage, isOn: $libraryRandomImage)

            } header: {
                L10n.library.text
            }

            Section {

                ChevronButton(title: L10n.library)
                    .onSelect {
                        router.route(to: \.itemFilterDrawerSelector, $libraryEnabledDrawerFilters)
                    }

                ChevronButton(title: L10n.search)
                    .onSelect {
                        router.route(to: \.itemFilterDrawerSelector, $searchEnabledDrawerFilters)
                    }

            } header: {
                L10n.filters.text
            }

            Section {
                Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)
                Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
            } header: {
                L10n.missingItems.text
            }

            Section {

                ChevronButton(title: L10n.indicators)
                    .onSelect {
                        router.route(to: \.indicatorSettings)
                    }

                Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                CaseIterablePicker(title: L10n.next, selection: $nextUpPosterType)

                CaseIterablePicker(title: L10n.recentlyAdded, selection: $recentlyAddedPosterType)

                CaseIterablePicker(title: L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType)

                CaseIterablePicker(title: L10n.recommended, selection: $similarPosterType)

                CaseIterablePicker(title: L10n.search, selection: $searchPosterType)

                // TODO: figure out how we can do the same Menu as the library menu picker?
                CaseIterablePicker(title: L10n.library, selection: $libraryViewType)

                if libraryViewType == .list, UIDevice.isPad {
                    BasicStepper(
                        title: "Columns",
                        value: $listColumnCount,
                        range: 1 ... 4,
                        step: 1
                    )
                }

            } header: {
                L10n.posters.text
            }

            Section {
                Toggle(L10n.seriesBackdrop, isOn: $useSeriesLandscapeBackdrop)
            } header: {
                // TODO: think of a better name
                L10n.episodeLandscapePoster.text
            }
        }
        .navigationTitle(L10n.customize)
    }
}
