//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension CustomizeViewsSettings {

    struct HomeSection: View {

        @Default(.Customization.Home.showRecentlyAdded)
        private var showRecentlyAdded

        @Default(.Customization.Home.maxNextUp)
        private var maxNextUp
        @Default(.Customization.Home.resumeNextUp)
        private var resumeNextUp

        var body: some View {

            Section(L10n.home) {

                // MARK: Show Recently Added Row

                Toggle(
                    L10n.showRecentlyAdded.localizedCapitalized,
                    isOn: $showRecentlyAdded
                )
            }

            Section {

                // MARK: Rewatched Items in Next Up

                Toggle(
                    L10n.nextUpRewatch.localizedCapitalized,
                    isOn: $resumeNextUp
                )

                // MARK: Maximum Duration in Next Up

                ChevronAlertButton(
                    L10n.nextUpDays.localizedCapitalized,
                    subtitle: {
                        if maxNextUp > 0 {
                            return Text(maxNextUp, format: .interval(style: .narrow, fields: [.day]))
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
            } header: {
                Text(L10n.nextUp)
            } footer: {
                Text(L10n.nextUpSettingsDescription)
            }
        }
    }
}
