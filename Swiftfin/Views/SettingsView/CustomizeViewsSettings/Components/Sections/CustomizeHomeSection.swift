//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: Fix the maxNextUp to allow changes. Currently doesn't do anything but looks great. Focus...
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
            self._maxNextUpDays = .init(initialValue: Int(_maxNextUp.wrappedValue / 86400))
        }

        var body: some View {
            Section(L10n.home) {

                Toggle(L10n.showRecentlyAdded, isOn: $showRecentlyAdded)

                Toggle(L10n.nextUpRewatch, isOn: $enableRewatching)

                ChevronButton(
                    L10n.nextUpDays,
                    subtitle: Text(
                        Date.now.addingTimeInterval(-maxNextUp) ..< Date.now,
                        format: .components(style: .narrow, fields: [.year, .month, .week, .day])
                    )
                )
                .onSelect {
                    isPresentingNextUpDays = true
                }
                .alert(L10n.nextUpDays, isPresented: $isPresentingNextUpDays) {

                    TextField(
                        L10n.nextUpDays,
                        value: $maxNextUpDays,
                        format: .number
                    )
                    .keyboardType(.numberPad)

                } message: {
                    Text(L10n.nextUpDaysDescription)
                }
                .onChange(of: isPresentingNextUpDays) { newValue in
                    guard !newValue else { return }

                    maxNextUp = TimeInterval(clamp(maxNextUpDays, min: 0, max: 1000)) * 86400
                }
            }
        }
    }
}
