//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

struct BasicAppSettingsView: View {

    @Default(.accentColor)
    private var accentColor
    @Default(.appAppearance)
    private var appAppearance

    @EnvironmentObject
    private var router: BasicAppSettingsCoordinator.Router

    @ObservedObject
    var viewModel: SettingsViewModel

    @State
    private var resetUserSettingsSelected: Bool = false
    @State
    private var resetAppSettingsSelected: Bool = false
    @State
    private var removeAllServersSelected: Bool = false

    var body: some View {
        Form {

            ChevronButton(title: L10n.about)
                .onSelect {
                    router.route(to: \.about)
                }

            Section {
                CaseIterablePicker(title: L10n.appearance, selection: $appAppearance)

                ChevronButton(title: L10n.appIcon)
                    .onSelect {
                        router.route(to: \.appIconSelector)
                    }
            } header: {
                L10n.accessibility.text
            }

            Section {
                ColorPicker(L10n.accentColor, selection: $accentColor, supportsOpacity: false)
            } footer: {
                L10n.accentColorDescription.text
            }

            ChevronButton(title: L10n.logs)
                .onSelect {
                    router.route(to: \.log)
                }

            Section {
                Button {
                    resetUserSettingsSelected = true
                } label: {
                    L10n.resetUserSettings.text
                }

                Button {
                    removeAllServersSelected = true
                } label: {
                    Text(L10n.removeAllServers)
                }
            }
        }
        .alert(L10n.resetUserSettings, isPresented: $resetUserSettingsSelected) {
            Button(L10n.reset, role: .destructive) {
                viewModel.resetUserSettings()
            }
        } message: {
            Text(L10n.resetAllSettings)
        }
        .alert(L10n.removeAllServers, isPresented: $removeAllServersSelected) {
            Button(L10n.reset, role: .destructive) {
                viewModel.removeAllServers()
            }
        }
        .navigationTitle(L10n.settings)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }
}
