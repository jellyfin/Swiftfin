//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

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

        @State
        private var isPresentingNextUpDays = false
        @State
        private var maxNextUpDays: Int

        init() {
            // Access Defaults directly without using self
            let initialMaxNextUp = Defaults[.Customization.Home.maxNextUp]
            self._maxNextUpDays = State(initialValue: Int(initialMaxNextUp / 86400))
        }

        var body: some View {
            Section(L10n.home) {

                Toggle(L10n.showRecentlyAdded, isOn: $showRecentlyAdded)

                Toggle(L10n.nextUpRewatch, isOn: $enableRewatching)

                ChevronButton(
                    L10n.nextUpDays,
                    subtitle: formatDuration()
                )
                .onSelect {
                    isPresentingNextUpDays = true
                }
                .sheet(isPresented: $isPresentingNextUpDays) {
                    // Inline view to mimic alert with TextField
                    VStack(spacing: 20) {
                        Text(L10n.nextUpDays)
                            .font(.title2)
                            .padding(.top, 40)

                        Text(L10n.nextUpDaysDescription)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        TextField(
                            L10n.nextUpDays,
                            value: $maxNextUpDays,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .frame(width: 200)
                        .padding()
                        .focusable(true)

                        HStack(spacing: 40) {
                            Button(L10n.cancel) {
                                isPresentingNextUpDays = false
                            }
                            .buttonStyle(DefaultButtonStyle())
                            .focusable(true)

                            Button(L10n.save) {
                                // Validate and save the input
                                maxNextUpDays = clamp(maxNextUpDays, min: 0, max: 1000)
                                maxNextUp = TimeInterval(maxNextUpDays) * 86400
                                isPresentingNextUpDays = false
                            }
                            .buttonStyle(DefaultButtonStyle())
                            .focusable(true)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding()
                }
            }
        }

        private func formatDuration() -> String {
            if maxNextUpDays == 0 {
                return L10n.disabled
            } else {
                let dateInterval = DateInterval(
                    start: Date.now.addingTimeInterval(-TimeInterval(maxNextUpDays * 86400)),
                    end: Date.now
                )
                return "" /* dateInterval.formatted(
                     .components(style: .narrow, fields: [.year, .month, .week, .day])
                 ) */
            }
        }
    }
}

// Helper function to clamp values
func clamp(_ value: Int, min: Int, max: Int) -> Int {
    Swift.max(min, Swift.min(value, max))
}
