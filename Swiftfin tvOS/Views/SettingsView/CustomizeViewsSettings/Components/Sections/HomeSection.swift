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

    struct HomeSection: View {

        // MARK: - Defaults

        @Default(.Customization.Home.showRecentlyAdded)
        private var showRecentlyAdded
        @Default(.Customization.Home.maxNextUp)
        private var maxNextUp
        @Default(.Customization.Home.resumeNextUp)
        private var resumeNextUp

        // MARK: - Next Up Days Variables

        @State
        private var tempNextUpDays: TimeInterval
        @State
        private var isPresentingNextUpDays = false

        // MARK: - Initializer

        init() {
            self.tempNextUpDays = Defaults[.Customization.Home.maxNextUp]
        }

        // MARK: - Body

        var body: some View {
            Section(L10n.home) {

                Toggle(L10n.showRecentlyAdded, isOn: $showRecentlyAdded)

                Toggle(L10n.nextUpRewatch, isOn: $resumeNextUp)

                nextUpDaysButton
            }
        }

        // MARK: - Next Up Days Button

        private var nextUpDaysButton: some View {
            ChevronAlertButton(
                L10n.nextUpDays,
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
                    value: $tempNextUpDays,
                    format: .dayInterval(range: 0 ... 1000)
                )
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
            } onSave: {
                maxNextUp = tempNextUpDays
            } onCancel: {
                tempNextUpDays = maxNextUp
            }
        }
    }
}
