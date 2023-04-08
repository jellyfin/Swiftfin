//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CustomizeViewsSettings: View {

    @Default(.Customization.itemViewType)
    var itemViewType
    @Default(.Customization.CinematicItemViewType.usePrimaryImage)
    private var cinematicItemViewTypeUsePrimaryImage

    @Default(.hapticFeedback)
    private var hapticFeedback

    @Default(.Customization.shouldShowMissingSeasons)
    var shouldShowMissingSeasons
    @Default(.Customization.shouldShowMissingEpisodes)
    var shouldShowMissingEpisodes

    @Default(.Customization.showPosterLabels)
    var showPosterLabels
    @Default(.Customization.nextUpPosterType)
    var nextUpPosterType
    @Default(.Customization.recentlyAddedPosterType)
    var recentlyAddedPosterType
    @Default(.Customization.latestInLibraryPosterType)
    var latestInLibraryPosterType
    @Default(.Customization.similarPosterType)
    var similarPosterType
    @Default(.Customization.searchPosterType)
    var searchPosterType
    @Default(.Customization.Library.gridPosterType)
    var libraryGridPosterType

    @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
    var useSeriesLandscapeBackdrop

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
                    EnumPicker(title: L10n.items, selection: $itemViewType)
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

                EnumPicker(title: L10n.next, selection: $nextUpPosterType)

                EnumPicker(title: L10n.recentlyAdded, selection: $recentlyAddedPosterType)

                EnumPicker(title: L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType)

                EnumPicker(title: L10n.recommended, selection: $similarPosterType)

                EnumPicker(title: L10n.search, selection: $searchPosterType)

                EnumPicker(title: L10n.library, selection: $libraryGridPosterType)
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
