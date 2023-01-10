//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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
    private var resetUserSettingsTapped: Bool = false
    @State
    private var resetAppSettingsTapped: Bool = false
    @State
    private var removeAllUsersTapped: Bool = false

    var body: some View {
        Form {

            Button {
                router.route(to: \.about)
            } label: {
                HStack {
                    L10n.about.text
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }

            Section {
                EnumPicker(title: L10n.appearance, selection: $appAppearance)

                ChevronButton(title: "App Icon")
                    .onSelect {
                        router.route(to: \.appIconSelector)
                    }
            } header: {
                L10n.accessibility.text
            }

            Section {
                ColorPicker("Accent Color", selection: $accentColor, supportsOpacity: false)
            } footer: {
                Text("Some views may need an app restart to update.")
            }

            ChevronButton(title: "Logs")
                .onSelect {
                    router.route(to: \.log)
                }

            Button {
                resetUserSettingsTapped = true
            } label: {
                L10n.resetUserSettings.text
            }

            Button {
                resetAppSettingsTapped = true
            } label: {
                L10n.resetAppSettings.text
            }

            Button {
                removeAllUsersTapped = true
            } label: {
                L10n.removeAllUsers.text
            }
        }
        .alert(L10n.resetUserSettings, isPresented: $resetUserSettingsTapped, actions: {
            Button(role: .destructive) {
//                viewModel.resetUserSettings()
            } label: {
                L10n.reset.text
            }
        })
        .alert(L10n.resetAppSettings, isPresented: $resetAppSettingsTapped, actions: {
            Button(role: .destructive) {
//                viewModel.resetAppSettings()
            } label: {
                L10n.reset.text
            }
        })
        .alert(L10n.removeAllUsers, isPresented: $removeAllUsersTapped, actions: {
            Button(role: .destructive) {
//                viewModel.removeAllUsers()
            } label: {
                L10n.reset.text
            }
        })
        .navigationBarTitle(L10n.settings)
        .navigationBarTitleDisplayMode(.inline)
        .navigationCloseButton() {
            router.dismissCoordinator()
        }
    }
}
