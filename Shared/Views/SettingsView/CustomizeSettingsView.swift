//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct CustomizeSettingsView: View {

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

    @Router
    private var router

    // MARK: - Body

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
                        Text(L10n.usePrimaryImageDescription)
                    }
                }
            }

            Section {

                Toggle(L10n.favorites, isOn: $showFavorites)
                Toggle(L10n.randomImage, isOn: $libraryRandomImage)

            } header: {
                Text(L10n.library)
            }

            Section {

                Toggle(L10n.letterPicker, isOn: $letterPickerEnabled)

                if letterPickerEnabled {
                    CaseIterablePicker(
                        L10n.orientation,
                        selection: $letterPickerOrientation
                    )
                }

                ChevronButton(L10n.library) {
                    router.route(to: .itemFilterDrawerSelector(selection: $libraryEnabledDrawerFilters))
                }

                ChevronButton(L10n.search) {
                    router.route(to: .itemFilterDrawerSelector(selection: $searchEnabledDrawerFilters))
                }

            } header: {
                Text(L10n.filters)
            }

            Section {
                Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)
                Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
            } header: {
                Text(L10n.missingItems)
            }

            Section(L10n.posters) {

                ChevronButton(L10n.indicators) {
                    router.route(to: .indicatorSettings)
                }

                Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                CaseIterablePicker(L10n.next, selection: $nextUpPosterType)
                    .onlySupportedCases(true)

                CaseIterablePicker(L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType)
                    .onlySupportedCases(true)

                CaseIterablePicker(L10n.recommended, selection: $similarPosterType)
                    .onlySupportedCases(true)

                CaseIterablePicker(L10n.search, selection: $searchPosterType)
                    .onlySupportedCases(true)
            }

            Section(L10n.libraries) {
                CaseIterablePicker(L10n.library, selection: $libraryDisplayType)

                CaseIterablePicker(L10n.posters, selection: $libraryPosterType)
                    .onlySupportedCases(true)

                if libraryDisplayType == .list, !UIDevice.isPhone {
                    BasicStepper(
                        L10n.columns,
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
                Text(L10n.episodeLandscapePoster)
            }
        }
        .navigationTitle(L10n.customize)
    }
}

// MARK: - HomeSection

extension CustomizeSettingsView {

    struct HomeSection: View {

        @Default(.Customization.Home.showRecentlyAdded)
        private var showRecentlyAdded
        @Default(.Customization.Home.maxNextUp)
        private var maxNextUp
        @Default(.Customization.Home.resumeNextUp)
        private var resumeNextUp

        var body: some View {
            Section(L10n.home) {

                Toggle(L10n.showRecentlyAdded, isOn: $showRecentlyAdded)

                Toggle(L10n.nextUpRewatch, isOn: $resumeNextUp)

                ChevronButton(
                    L10n.nextUpDays,
                    subtitle: {
                        if maxNextUp > 0 {
                            let duration = Duration.seconds(TimeInterval(maxNextUp))
                            return Text(duration, format: .units(allowed: [.days], width: .abbreviated))
                        } else {
                            return Text(L10n.disabled)
                        }
                    }(),
                    description: L10n.nextUpDaysDescription
                ) {
                    TextField(
                        L10n.days,
                        value: $maxNextUp,
                        format: .dayInterval(range: 0 ... 1000)
                    )
                    .keyboardType(.numberPad)
                }
            }
        }
    }
}

// MARK: - ItemSection

extension CustomizeSettingsView {

    struct ItemSection: View {

        @Injected(\.currentUserSession)
        private var userSession

        @Router
        private var router

        @StoredValue(.User.itemViewAttributes)
        private var itemViewAttributes
        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers

        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing
        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement

        var body: some View {
            Section(L10n.items) {

                ChevronButton(L10n.mediaAttributes) {
                    router.route(to: .itemViewAttributes(selection: $itemViewAttributes))
                }

                CaseIterablePicker(
                    L10n.enabledTrailers,
                    selection: $enabledTrailers
                )

                if userSession?.user.permissions.items.canManageCollections == true {
                    Toggle(L10n.editCollections, isOn: $enableCollectionManagement)
                }

                if userSession?.user.permissions.items.canEditMetadata == true ||
                    userSession?.user.permissions.items.canManageLyrics == true ||
                    userSession?.user.permissions.items.canManageSubtitles == true
                {
                    Toggle(L10n.editMedia, isOn: $enableItemEditing)
                }

                if userSession?.user.permissions.items.canDelete == true {
                    Toggle(L10n.deleteMedia, isOn: $enableItemDeletion)
                }
            }
        }
    }
}
