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

    @Default(.Customization.Library.enabledDrawerFilters)
    private var libraryEnabledDrawerFilters
    @Default(.Customization.Search.enabledDrawerFilters)
    private var searchEnabledDrawerFilters

    @Default(.Customization.recentlyAddedPosterType)
    private var showRecentlyAdded

    @Default(.Customization.Library.showFavorites)
    private var showFavorites
    @Default(.Customization.Library.randomImage)
    private var libraryRandomImage

    @Router
    private var router

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
                ChevronButton(L10n.library) {
                    router.route(to: .itemFilterDrawerSelector(selection: $libraryEnabledDrawerFilters))
                }

                ChevronButton(L10n.search) {
                    router.route(to: .itemFilterDrawerSelector(selection: $searchEnabledDrawerFilters))
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

            ChevronButton(L10n.libraries) {
                router.route(to: .librarySettings)
            }

            ChevronButton(L10n.posters) {
                router.route(to: .posterSettings)
            }

            ItemSection()

            HomeSection()
        }
        .navigationTitle(L10n.customize)
    }
}
