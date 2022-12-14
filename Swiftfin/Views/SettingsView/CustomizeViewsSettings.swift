//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CustomizeViewsSettings: View {

    @Default(.Customization.itemViewType)
    var itemViewType
    @Default(.Customization.CinematicItemViewType.usePrimaryImage)
    private var cinematicItemViewTypeUsePrimaryImage

    @Default(.shouldShowMissingSeasons)
    var shouldShowMissingSeasons
    @Default(.shouldShowMissingEpisodes)
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

    var body: some View {
        List {

            if UIDevice.isPhone {
                Section {
                    EnumPicker(title: L10n.items, selection: $itemViewType)
                }

                if itemViewType == .cinematic {
                    Section {
                        Toggle("Use Primary Image", isOn: $cinematicItemViewTypeUsePrimaryImage)
                    } footer: {
                        Text("Uses the primary image and hides the logo.")
                    }
                }
            }

            Section {
                Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)
                Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
            } header: {
                L10n.missingItems.text
            }

            Section {

                Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                EnumPicker(title: L10n.next, selection: $nextUpPosterType)

                EnumPicker(title: L10n.recentlyAdded, selection: $recentlyAddedPosterType)

                EnumPicker(title: L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType)

                EnumPicker(title: L10n.recommended, selection: $similarPosterType)

                EnumPicker(title: L10n.search, selection: $searchPosterType)

                EnumPicker(title: L10n.library, selection: $libraryGridPosterType)
            } header: {
                // TODO: localize after organization
                Text("Posters")
            }

            Section {
                Toggle("Series Backdrop", isOn: $useSeriesLandscapeBackdrop)
            } header: {
                // TODO: think of a better name
                // TODO: localize after organization
                Text("Episode Landscape Poster")
            }

            Section {
                Toggle("Random Image", isOn: $libraryRandomImage)

                Toggle("Show Favorites", isOn: $showFavorites)
            } header: {
                Text("Library")
            }
        }
        .navigationTitle(L10n.customize)
    }
}
