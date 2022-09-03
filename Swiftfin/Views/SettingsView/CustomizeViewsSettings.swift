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
    @Default(.Customization.recommendedPosterType)
    var recommendedPosterType
    @Default(.Customization.searchPosterType)
    var searchPosterType
    @Default(.Customization.Library.gridPosterType)
    var libraryGridPosterType

    @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
    var useSeriesLandscapeBackdrop

    var body: some View {
        List {
            Section {
                Picker(L10n.items, selection: $itemViewType) {
                    ForEach(ItemViewType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type.rawValue)
                    }
                }

            } header: {
                EmptyView()
            }

            Section {
                Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)
                Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
            } header: {
                L10n.missingItems.text
            }

            Section {

                Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                Picker(L10n.nextUp, selection: $nextUpPosterType) {
                    ForEach(PosterType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type.rawValue)
                    }
                }

                Picker(L10n.recentlyAdded, selection: $recentlyAddedPosterType) {
                    ForEach(PosterType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type.rawValue)
                    }
                }

                Picker(L10n.latestWithString(L10n.library), selection: $latestInLibraryPosterType) {
                    ForEach(PosterType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type.rawValue)
                    }
                }

                // TODO: Take time to do this for a lot of views
//                Picker(L10n.recommended, selection: $recommendedPosterType) {
//                    ForEach(PosterType.allCases, id: \.self) { type in
//                        Text(type.localizedName).tag(type.rawValue)
//                    }
//                }

                Picker(L10n.search, selection: $searchPosterType) {
                    ForEach(PosterType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type.rawValue)
                    }
                }

                Picker(L10n.library, selection: $libraryGridPosterType) {
                    ForEach(PosterType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type.rawValue)
                    }
                }
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
        }
        .navigationTitle(L10n.customize)
    }
}
