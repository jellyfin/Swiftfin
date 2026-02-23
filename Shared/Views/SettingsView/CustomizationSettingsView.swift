//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct CustomizationSettingsView: View {

    // MARK: - Home Defaults

    @Default(.Customization.Home.showRecentlyAdded)
    private var showRecentlyAdded
    @Default(.Customization.Home.resumeNextUp)
    private var resumeNextUp
    @Default(.Customization.Home.maxNextUp)
    private var maxNextUp

    // MARK: - Media Defaults

    @Default(.Customization.Library.showFavorites)
    private var showFavorites
    @Default(.Customization.Library.randomImage)
    private var libraryRandomImage

    // MARK: - Library Defaults

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

    // MARK: - Poster Defaults

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

    // MARK: - Filter Defaults

    @Default(.Customization.Library.letterPickerEnabled)
    private var letterPickerEnabled
    @Default(.Customization.Library.letterPickerOrientation)
    private var letterPickerOrientation
    @Default(.Customization.Library.enabledDrawerFilters)
    private var libraryEnabledDrawerFilters
    @Default(.Customization.Search.enabledDrawerFilters)
    private var searchEnabledDrawerFilters

    // MARK: - Item Defaults

    @StoredValue(.User.itemViewAttributes)
    private var itemViewAttributes
    @StoredValue(.User.enabledTrailers)
    private var enabledTrailers
    @Default(.Customization.shouldShowMissingSeasons)
    private var shouldShowMissingSeasons
    @Default(.Customization.shouldShowMissingEpisodes)
    private var shouldShowMissingEpisodes
    @StoredValue(.User.enableCollectionManagement)
    private var enableCollectionManagement
    @StoredValue(.User.enableItemEditing)
    private var enableItemEditing
    @StoredValue(.User.enableItemDeletion)
    private var enableItemDeletion

    // MARK: - Item View Defaults

    @Default(.Customization.itemViewType)
    private var itemViewType
    @Default(.Customization.CinematicItemViewType.usePrimaryImage)
    private var cinematicItemViewTypeUsePrimaryImage
    @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
    private var useSeriesLandscapeBackdrop

    // MARK: - User Permissions

    @Injected(\.currentUserSession)
    private var userSession

    private var userPolicy: UserPolicy? {
        userSession?.user.data.policy
    }

    @Router
    private var router

    var body: some View {
        Form(systemImage: "gearshape") {
            homeSettings

            mediaSettings

            filterSettings

            librarySettings

            posterSettings

            itemSettings

            itemViewSettings

            itemManagementSettings
        }
        .navigationTitle(L10n.customization)
    }

    // MARK: - Home Settings

    @ViewBuilder
    private var homeSettings: some View {
        Section(L10n.home) {
            Toggle(L10n.recentlyAdded, isOn: $showRecentlyAdded)

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

    // MARK: - Media Settings

    @ViewBuilder
    private var mediaSettings: some View {
        Section(L10n.media) {
            Toggle(L10n.favorites, isOn: $showFavorites)

            Toggle(L10n.randomImage, isOn: $libraryRandomImage)
        }
    }

    // MARK: - Filter Settings

    @ViewBuilder
    private var filterSettings: some View {
        Section(L10n.filters) {
            Toggle(L10n.letterPicker, isOn: $letterPickerEnabled)

            if letterPickerEnabled {
                #if os(iOS)
                Picker(L10n.orientation, selection: $letterPickerOrientation)
                #else
                ListRowMenu(L10n.orientation, selection: $letterPickerOrientation)
                #endif
            }

            ChevronButton(L10n.library) {
                router.route(to: .itemFilterDrawerSelector(selection: $libraryEnabledDrawerFilters))
            }

            ChevronButton(L10n.search) {
                router.route(to: .itemFilterDrawerSelector(selection: $searchEnabledDrawerFilters))
            }
        }
    }

    // MARK: - Library Settings

    @ViewBuilder
    private var librarySettings: some View {
        Section(L10n.libraries) {
            #if os(iOS)
            Picker(L10n.posters, selection: $libraryPosterType)
            Picker(L10n.defaultLayout, selection: $libraryDisplayType)
            #else
            ListRowMenu(L10n.posters, selection: $libraryPosterType)
            ListRowMenu(L10n.defaultLayout, selection: $libraryDisplayType)
            #endif

            if libraryDisplayType == .list, UIDevice.isPad {
                #if os(iOS)
                Stepper(L10n.columns, value: $listColumnCount, in: 1 ... 3, step: 1) { _ in
                    LabeledContent(L10n.columns) {
                        Text(listColumnCount.description)
                    }
                }
                #else
                Stepper(L10n.columns, value: $listColumnCount, in: 1 ... 4, step: 1) {
                    LabeledContent(L10n.columns) {
                        Text(listColumnCount.description)
                    }
                }
                #endif
            }

            Toggle(L10n.rememberLayout, isOn: $rememberLibraryLayout)

            Toggle(L10n.rememberSorting, isOn: $rememberLibrarySort)
        }
    }

    // MARK: - Poster Settings

    @ViewBuilder
    private var posterSettings: some View {
        Section(L10n.posters) {
            Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

            ChevronButton(L10n.indicators) {
                router.route(to: .indicatorSettings)
            }

            #if os(iOS)
            Picker(L10n.nextUp, selection: $nextUpPosterType)
            Picker(L10n.recentlyAdded, selection: $recentlyAddedPosterType)
            Picker(L10n.latestWithString(L10n.library.localizedLowercase), selection: $latestInLibraryPosterType)
            Picker(L10n.recommended, selection: $similarPosterType)
            Picker(L10n.search, selection: $searchPosterType)
            #else
            ListRowMenu(L10n.nextUp, selection: $nextUpPosterType)
            ListRowMenu(L10n.recentlyAdded, selection: $recentlyAddedPosterType)
            ListRowMenu(L10n.latestWithString(L10n.library.localizedLowercase), selection: $latestInLibraryPosterType)
            ListRowMenu(L10n.recommended, selection: $similarPosterType)
            ListRowMenu(L10n.search, selection: $searchPosterType)
            #endif
        }
    }

    // MARK: - Item Settings

    @ViewBuilder
    private var itemSettings: some View {
        Section(L10n.items) {
            ChevronButton(L10n.mediaAttributes) {
                router.route(to: .itemViewAttributes(selection: $itemViewAttributes))
            }

            #if os(iOS)
            Picker(L10n.enabledTrailers, selection: $enabledTrailers)
            #else
            ListRowMenu(L10n.enabledTrailers, selection: $enabledTrailers)
            #endif

            Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)

            Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
        }
    }

    // MARK: - Item View Settings

    @ViewBuilder
    private var itemViewSettings: some View {
        if UIDevice.isPhone {
            Section {
                #if os(iOS)
                Picker(L10n.type, selection: $itemViewType)
                #else
                ListRowMenu(L10n.type, selection: $itemViewType)
                #endif

                if itemViewType == .cinematic {
                    Toggle(L10n.usePrimaryImage, isOn: $cinematicItemViewTypeUsePrimaryImage)
                }

                Toggle(L10n.useSeriesImageForEpisodes, isOn: $useSeriesLandscapeBackdrop)
            } header: {
                Text(L10n.itemView)
            } footer: {
                if itemViewType == .cinematic {
                    Text(L10n.usePrimaryImageDescription)
                }
            }
        }
    }

    // MARK: - Item Management Settings

    @ViewBuilder
    private var itemManagementSettings: some View {
        if UIDevice.isPhone {
            Section(L10n.itemManagement) {

                /// Collections can be edited by users or by setting
                if userPolicy?.isAdministrator == true ||
                    userPolicy?.enableCollectionManagement == true
                {
                    Toggle(L10n.editCollections, isOn: $enableCollectionManagement)
                }

                /// Only allow editing if administrator
                /// - Does NOT include subtitle / lyric editing
                if userPolicy?.isAdministrator == true {
                    Toggle(L10n.editMedia, isOn: $enableItemEditing)
                }

                /// Only allow deletion if there is someting to delete from
                if userPolicy?.enableContentDeletion == true ||
                    userPolicy?.enableContentDeletionFromFolders?.isNotEmpty == true
                {
                    Toggle(L10n.deleteMedia, isOn: $enableItemDeletion)
                }
            }
        }
    }
}
