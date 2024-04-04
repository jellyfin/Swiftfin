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

    @EnvironmentObject
    private var router: BasicAppSettingsCoordinator.Router

    @ObservedObject
    var viewModel: SettingsViewModel

    @State
    private var resetUserSettingsSelected: Bool = false
    @State
    private var removeAllServersSelected: Bool = false

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section {

                    Button {
                        TextPairView(
                            leading: L10n.version,
                            trailing: "\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))"
                        )
                    }

                    ChevronButton(title: "Logs")
                        .onSelect {
                            router.route(to: \.log)
                        }
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
                        Text("Remove All Servers")
                    }
                }
            }
            .withDescriptionTopPadding()
            .navigationTitle(L10n.settings)
            .alert(L10n.resetUserSettings, isPresented: $resetUserSettingsSelected) {
                Button(L10n.reset, role: .destructive) {
                    viewModel.resetUserSettings()
                }
            } message: {
                Text("Reset all settings back to defaults.")
            }
            .alert("Remove All Servers", isPresented: $removeAllServersSelected) {
                Button(L10n.reset, role: .destructive) {
                    viewModel.removeAllServers()
                }
            }
    }
}
