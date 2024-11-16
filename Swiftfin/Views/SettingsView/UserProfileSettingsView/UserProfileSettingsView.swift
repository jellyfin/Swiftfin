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
                ChevronButton("Security")
                    .onSelect {
                        router.route(to: \.localSecurity)
                    }
            }

            Section {
                // TODO: move under future "Storage" tab
                //       when downloads implemented
                Button("Reset Settings") {
                    isPresentingConfirmReset = true
                }
                .foregroundStyle(.red)
            } footer: {
                Text("Reset Swiftfin user settings")
            }
        }
        .alert("Reset Settings", isPresented: $isPresentingConfirmReset) {
            Button(L10n.reset, role: .destructive) {
                do {
                    try viewModel.userSession.user.deleteSettings()
                } catch {
                    viewModel.logger.error("Unable to reset user settings: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to reset all user settings?")
        }
        .confirmationDialog(
            "Profile Image",
            isPresented: $isPresentingProfileImageOptions,
            titleVisibility: .visible
        ) {

            Button("Select Image") {
                router.route(to: \.photoPicker, viewModel.userSession.user.id)
            }

            Button(L10n.delete, role: .destructive) {
                viewModel.deleteCurrentUserProfileImage()
            }
        }
    }
}
