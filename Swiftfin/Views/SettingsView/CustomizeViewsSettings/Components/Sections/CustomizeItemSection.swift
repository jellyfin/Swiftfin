//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension CustomizeViewsSettings {
    struct CustomizeItemSection: View {
        @Default(.Customization.itemViewType)
        private var itemViewType
        @Default(.Customization.CinematicItemViewType.usePrimaryImage)
        private var cinematicItemViewTypeUsePrimaryImage

        @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
        private var useSeriesLandscapeBackdrop

        @Default(.Customization.shouldShowMissingSeasons)
        private var shouldShowMissingSeasons
        @Default(.Customization.shouldShowMissingEpisodes)
        private var shouldShowMissingEpisodes

        var body: some View {
            if UIDevice.isPhone {
                Section {
                    CaseIterablePicker(L10n.items, selection: $itemViewType)
                } header: {
                    Text("Media Items")
                } footer: {
                    // L10n.itemsDescription.text
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
                Toggle(L10n.seriesBackdrop, isOn: $useSeriesLandscapeBackdrop)
            } footer: {
                // TODO: think of a better name
                L10n.episodeLandscapePoster.text
            }

            Section {
                Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)

                Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
            } header: {
                L10n.missingItems.text
            } footer: {
                // L10n.missingItemsDescription.text
            }
        }
    }
}
