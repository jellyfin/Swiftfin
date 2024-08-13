//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
    private var recentlyAddedPosterType
    @Default(.Customization.showRecentlyAdded)
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

    @Default(.Customization.Home.homeLabels)
    private var homeLabels
    @Default(.Customization.Home.homeSections)
    private var homeSections

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

            Section(L10n.library) {

                Toggle(L10n.favorites, isOn: $showFavorites)
                Toggle(L10n.randomImage, isOn: $libraryRandomImage)

            }

            Section(L10n.filters) {

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
            }

            Section(L10n.missingItems) {
                Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)
                Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
            }

            Section(L10n.posters) {
                ChevronButton(L10n.indicators)
                    .onSelect {
                        router.route(to: \.indicatorSettings)
                    }

                Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                CaseIterablePicker(L10n.next, selection: $nextUpPosterType)
                CaseIterablePicker(L10n.recentlyAdded, selection: $recentlyAddedPosterType)
                CaseIterablePicker(L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType)
                CaseIterablePicker(L10n.recommended, selection: $similarPosterType)
                CaseIterablePicker(L10n.search, selection: $searchPosterType)
            }

            Section("Libraries") {
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
            }

            Section(L10n.home) {
                Toggle("Show Recently Added", isOn: $showRecentlyAdded)
                Toggle("Show Section Labels", isOn: $homeLabels)

                ChevronButton("Sections")
                    .onSelect {
                        router.route(to: \.homeSectionsSelector, $homeSections)
                    }
            }

            Section {
                Toggle("Remember Layout", isOn: $rememberLibraryLayout)
            } footer: {
                Text("Remember layout for individual libraries")
            }

            Section {
                Toggle("Remember Sorting", isOn: $rememberLibrarySort)
            } footer: {
                Text("Remember sorting for individual libraries")
            }

            // TODO: think of a better name
            Section(L10n.episodeLandscapePoster) {
                Toggle(L10n.seriesBackdrop, isOn: $useSeriesLandscapeBackdrop)
            }
        }
        .navigationTitle(L10n.customize)
    }
}
