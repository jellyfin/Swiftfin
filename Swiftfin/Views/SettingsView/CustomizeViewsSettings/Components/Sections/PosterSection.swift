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

    struct PosterSection: View {

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

        @EnvironmentObject
        private var router: SettingsCoordinator.Router

        var body: some View {

            Section(L10n.posters) {

                // MARK: Poster Indicator(s) Overlay

                ChevronButton(L10n.indicators.localizedCapitalized)
                    .onSelect {
                        router.route(to: \.indicatorSettings)
                    }

                // MARK: Show Poster Labels

                Toggle(
                    L10n.showPosterLabels.localizedCapitalized,
                    isOn: $showPosterLabels
                )

                // MARK: Poster Type - Home Next Up Items

                CaseIterablePicker(
                    L10n.next.localizedCapitalized,
                    selection: $nextUpPosterType
                )

                // MARK: Poster Type - Home Latest Library Items

                CaseIterablePicker(
                    L10n.latestWithString(L10n.library).localizedCapitalized,
                    selection: $latestInLibraryPosterType
                )

                // MARK: Poster Type - Recommended/Suggested Items

                CaseIterablePicker(
                    L10n.recommended.localizedCapitalized,
                    selection: $similarPosterType
                )

                // MARK: Poster Type - Search Result Items

                CaseIterablePicker(
                    L10n.search.localizedCapitalized,
                    selection: $searchPosterType
                )
            }
        }
    }
}
