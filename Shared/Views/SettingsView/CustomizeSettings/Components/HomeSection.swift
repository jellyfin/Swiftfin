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

extension CustomizeSettingsView {

    struct HomeSection: View {

        @Default(.Customization.Home.showRecentlyAdded)
        private var showRecentlyAdded
        @Default(.Customization.Home.showRecentlyPlayed)
        private var showRecentlyPlayed
        @Default(.Customization.Home.maxNextUp)
        private var maxNextUp
        @Default(.Customization.Home.Rewatching.configuration)
        private var rewatchingConfiguration

        @ContentBuilder
        var body: some View {
            Form(systemImage: "gear") {
                Section {
                    Toggle(L10n.recentlyAdded, isOn: $showRecentlyAdded)
                    Toggle(L10n.recentlyPlayed, isOn: $showRecentlyPlayed)
                } header: {
                    Text(L10n.sections)
                }

                Section {
                    Toggle(L10n.continueWatching, isOn: $rewatchingConfiguration.resume)
                    Toggle(L10n.nextUp, isOn: $rewatchingConfiguration.nextUp)

                    if showRecentlyAdded {
                        Toggle(L10n.recentlyAdded, isOn: $rewatchingConfiguration.recentlyAdded)
                    }

                    Toggle(L10n.latest, isOn: $rewatchingConfiguration.latest)
                } header: {
                    Text(L10n.rewatching)
                } footer: {
                    Text(L10n.rewatchingDescription)
                }

                Section {
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
                } header: {
                    Text(L10n.nextUp)
                }
            }
            .navigationTitle(L10n.home)
        }
    }
}
