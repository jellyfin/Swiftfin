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

        @Default(.Customization.Home.showRecentlyAdded)
        private var showRecentlyAdded
        @Default(.Customization.Home.maxNextUp)
        private var maxNextUp
        @Default(.Customization.Home.resumeNextUp)
        private var resumeNextUp

        @State
        var tempNextUp: TimeInterval?

        // MARK: - Init

        init() {
            _tempNextUp = State(initialValue: maxNextUp)
        }

        // MARK: - Body

        var body: some View {
            Section(L10n.home) {

                Toggle(L10n.showRecentlyAdded, isOn: $showRecentlyAdded)

                Toggle(L10n.nextUpRewatch, isOn: $resumeNextUp)

                ChevronInputButton(
                    title: L10n.nextUpDays,
                    subtitleText: {
                        if maxNextUp > 0 {
                            return Text(
                                Date.now.addingTimeInterval(-maxNextUp) ..< Date.now,
                                format: .components(style: .narrow, fields: [.year, .month, .week, .day])
                            )
                        } else {
                            return Text(L10n.disabled)
                        }
                    }(),
                    description: L10n.nextUpDaysDescription
                ) {
                    TextField(
                        L10n.nextUpDays,
                        value: $tempNextUp,
                        format: .dayInterval(range: 0 ... 1000)
                    )
                    .keyboardType(.numberPad)
                } onSave: {
                    if let tempNextUp = tempNextUp {
                        maxNextUp = tempNextUp
                    }
                } onCancel: {
                    tempNextUp = maxNextUp
                }
            }
        }
    }
}
