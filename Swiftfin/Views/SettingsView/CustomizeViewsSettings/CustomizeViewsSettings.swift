//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: will be entirely re-organized

struct CustomizeViewsSettings: View {

    @Default(.Customization.itemViewType)
    private var itemViewType
    @Default(.Customization.CinematicItemViewType.usePrimaryImage)
    private var cinematicItemViewTypeUsePrimaryImage

    @Default(.Customization.shouldShowMissingSeasons)
    private var shouldShowMissingSeasons
    @Default(.Customization.shouldShowMissingEpisodes)
    private var shouldShowMissingEpisodes

    @Default(.Customization.Library.letterPickerEnabled)
    var letterPickerEnabled
    @Default(.Customization.Library.letterPickerOrientation)
    var letterPickerOrientation
    @Default(.Customization.Library.enabledDrawerFilters)
    private var libraryEnabledDrawerFilters
    @Default(.Customization.Search.enabledDrawerFilters)
    private var searchEnabledDrawerFilters

    @Default(.Customization.showPosterLabels)
    private var showPosterLabels
    @Default(.Customization.nextUpPosterType)
    private var nextUpPosterType
    @Default(.Customization.recentlyAddedPosterType)
    private var showRecentlyAdded
    @Default(.Customization.latestInLibraryPosterType)
    private var latestInLibraryPosterType
    @Default(.Customization.similarPosterType)
    private var similarPosterType
    @Default(.Customization.searchPosterType)
    private var searchPosterType
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
                    CaseIterablePicker(L10n.items, selection: $itemViewType)
                }

                if itemViewType == .cinematic {
                    Section {
                        Toggle(L10n.usePrimaryImage, isOn: $cinematicItemViewTypeUsePrimaryImage)
                    } footer: {
                        L10n.usePrimaryImageDescription.text
                    }
                }
            }

            Section {

                Toggle(L10n.favorites, isOn: $showFavorites)
                Toggle(L10n.randomImage, isOn: $libraryRandomImage)

            } header: {
                L10n.library.text
            }

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
            }

            Section {
                Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)
                Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
            } header: {
                L10n.missingItems.text
            }

            Section(L10n.posters) {

                ChevronButton(L10n.indicators)
                    .onSelect {
                        router.route(to: \.indicatorSettings)
                    }

                Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                CaseIterablePicker(L10n.next, selection: $nextUpPosterType)

                CaseIterablePicker(L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType)

                CaseIterablePicker(L10n.recommended, selection: $similarPosterType)

                CaseIterablePicker(L10n.search, selection: $searchPosterType)
            }

            Section("Libraries") {
                CaseIterablePicker(L10n.library, selection: $libraryDisplayType)

                CaseIterablePicker(L10n.posters, selection: $libraryPosterType)

                if libraryDisplayType == .list, UIDevice.isPad {
                    BasicStepper(
                        title: L10n.columns,
                        value: $listColumnCount,
                        range: 1 ... 4,
                        step: 1
                    )
                }
            }

            ItemSection()

            HomeSection()

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
