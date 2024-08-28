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
    struct CustomizePosterSection: View {
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
        @Default(.Customization.Library.displayType)
        private var libraryViewType

        @EnvironmentObject
        private var router: SettingsCoordinator.Router

        var body: some View {
            Section {
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

                CaseIterablePicker(L10n.library, selection: $libraryViewType)
            } header: {
                L10n.posters.text
            } footer: {
                // L10n.postersDescription.text
            }
        }
    }
}
