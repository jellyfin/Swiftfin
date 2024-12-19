//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct UserProfileSettingsView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var viewModel: SettingsViewModel
    @ObservedObject
    var profileViewModel: UserProfileImageViewModel

    @State
    private var isPresentingConfirmReset: Bool = false
    @State
    private var isPresentingProfileImageOptions: Bool = false

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self.profileViewModel = .init(userID: viewModel.userSession.user.id)
    }

    var body: some View {
        List {
            UserProfileImage(
                username: viewModel.userSession.user.username,
                imageSource: viewModel.userSession.user.profileImageSource(
                    client: viewModel.userSession.client,
                    maxWidth: 120
                )
            ) {
                router.route(to: \.photoPicker, profileViewModel)
            } delete: {
                profileViewModel.send(.delete)
            }

            Section {
                ChevronButton(L10n.quickConnect)
                    .onSelect {
                        router.route(to: \.quickConnect)
                    }

                ChevronButton(L10n.password)
                    .onSelect {
                        router.route(to: \.resetUserPassword, viewModel.userSession.user.id)
                    }
            }

            Section {
                ChevronButton(L10n.security)
                    .onSelect {
                        router.route(to: \.localSecurity)
                    }
            }

            Section {
                // TODO: move under future "Storage" tab
                //       when downloads implemented
                Button(L10n.resetSettings) {
                    isPresentingConfirmReset = true
                }
                .foregroundStyle(.red)
            } footer: {
                Text(L10n.resetSettingsDescription)
            }
        }
        .confirmationDialog(
            L10n.resetSettings,
            isPresented: $isPresentingConfirmReset,
            titleVisibility: .visible
        ) {
            Button(L10n.reset, role: .destructive) {
                do {
                    try viewModel.userSession.user.deleteSettings()
                } catch {
                    viewModel.logger.error("Unable to reset user settings: \(error.localizedDescription)")
                }
            }
        } message: {
            Text(L10n.resetSettingsMessage)
        }
    }
}
