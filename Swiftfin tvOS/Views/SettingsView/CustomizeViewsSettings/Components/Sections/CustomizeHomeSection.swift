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
    struct CustomizeHomeSection: View {

        @Default(.Customization.Home.showRecentlyAdded)
        private var showRecentlyAdded
        @Default(.Customization.Home.maxNextUp)
        private var maxNextUp
        @Default(.Customization.Home.enableRewatching)
        private var enableRewatching

        @EnvironmentObject
        private var router: CustomizeSettingsCoordinator.Router

        var body: some View {
            Section {
                Toggle(L10n.showRecentlyAdded, isOn: $showRecentlyAdded)
                Toggle(L10n.nextUpRewatch, isOn: $enableRewatching)
                ChevronButton(
                    L10n.nextUp,
                    subtitle: maxNextUp == 0 ? L10n.disabled :
                        maxNextUp == 1 ? "\(maxNextUp) " + L10n.day :
                        "\(maxNextUp) " + L10n.days
                )
                .onSelect {
                    router.route(to: \.nextUpDaysSettings, $maxNextUp)
                }
            } header: {
                L10n.home.text
            } footer: {
                L10n.nextUpDaysDescription.text
            }
        }
    }
}
