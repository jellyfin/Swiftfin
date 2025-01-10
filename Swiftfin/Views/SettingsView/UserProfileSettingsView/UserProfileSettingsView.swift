//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct UserProfileSettingsView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    private var viewModel: SettingsViewModel
    @StateObject
    private var profileImageViewModel: UserProfileImageViewModel

    @State
    private var isPresentingConfirmReset: Bool = false

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self._profileImageViewModel = StateObject(wrappedValue: UserProfileImageViewModel(user: viewModel.userSession.user.data))
    }

    var body: some View {
        List {
            UserProfileHeroImage(
                user: profileImageViewModel.user,
                source: viewModel.userSession.user.profileImageSource(
                    client: viewModel.userSession.client,
                    maxWidth: 150
                )
            ) {
                router.route(to: \.photoPicker, profileImageViewModel)
            } onDelete: {
                profileImageViewModel.send(.delete)
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
