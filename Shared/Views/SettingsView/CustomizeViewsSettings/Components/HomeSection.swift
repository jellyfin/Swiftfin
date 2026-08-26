//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import SwiftUI

extension CustomizeViewsSettings {

    struct HomeSection: View {

        @Default(.Customization.Home.showRecentlyAdded)
        private var showRecentlyAdded
        @Default(.Customization.Home.showRecentlyPlayed)
        private var showRecentlyPlayed
        @Default(.Customization.Home.maxNextUp)
        private var maxNextUp
        @Default(.Customization.Home.resumeNextUp)
        private var resumeNextUp
        @Default(.Customization.Home.showLatestPrefix)
        private var showLatestPrefix

        var body: some View {
            Section(L10n.home) {

                Toggle(L10n.recentlyAdded, isOn: $showRecentlyAdded)
                Toggle(L10n.recentlyPlayed, isOn: $showRecentlyPlayed)
                Toggle(L10n.nextUpRewatch, isOn: $resumeNextUp)
                Toggle(L10n.latestInLibraryPrefix, isOn: $showLatestPrefix)

                StateAdapter(initialValue: false) { isNextUpDaysPresented in
                    ChevronButton {
                        isNextUpDaysPresented.wrappedValue = true
                    } label: {
                        LabeledContent {
                            if maxNextUp > 0 {
                                Text(
                                    Duration.seconds(maxNextUp),
                                    format: .units(allowed: [.days], width: .abbreviated)
                                )
                                .foregroundStyle(.secondary)
                            } else {
                                Text(L10n.disabled)
                                    .foregroundStyle(.secondary)
                            }
                        } label: {
                            Text(L10n.nextUpDays)
                        }
                    }
                    .alert(
                        L10n.nextUpDays,
                        isPresented: isNextUpDaysPresented
                    ) {
                        TextField(
                            L10n.days,
                            value: $maxNextUp,
                            format: .dayInterval(range: 0 ... 1000)
                        )
                        .keyboardType(.numberPad)
                    } message: {
                        Text(L10n.nextUpDaysDescription)
                    }
                }
            }
        }
    }
}
