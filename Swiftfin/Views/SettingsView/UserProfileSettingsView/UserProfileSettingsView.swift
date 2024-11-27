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

    @State
    private var isPresentingConfirmReset: Bool = false
    @State
    private var isPresentingProfileImageOptions: Bool = false

    var body: some View {
        List {
            UserProfileImagePicker.ProfileImageSection(
                imageSource: viewModel.userSession.user.profileImageSource(
                    client: viewModel.userSession.client,
                    maxWidth: 120
                ),
                username: viewModel.userSession.user.username
            ) {
                isPresentingProfileImageOptions = true
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
                Text(L10n.resetSettingsFooter)
            }
        }
        .alert(L10n.resetSettings, isPresented: $isPresentingConfirmReset) {
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
        .confirmationDialog(
            L10n.profileImage,
            isPresented: $isPresentingProfileImageOptions,
            titleVisibility: .visible
        ) {

            Button(L10n.selectImage) {
                router.route(to: \.photoPicker, viewModel.userSession.user.id)
            }

            Button(L10n.delete, role: .destructive) {
                viewModel.deleteCurrentUserProfileImage()
            }
        }
    }
}
