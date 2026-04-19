//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import Factory
import JellyfinAPI
import SwiftUI

struct LocalUserSettingsView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: SettingsViewModel

    @StateObject
    private var profileImageViewModel: UserImageViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self._profileImageViewModel = StateObject(wrappedValue: UserImageViewModel(item: viewModel.userSession.user.data))
    }

    var body: some View {
        Form {
            #if os(iOS)
            StateAdapter(initialValue: false) { isPhotoPickerPresented in
                UserProfileHeroImage(
                    user: profileImageViewModel.item,
                    source: viewModel.userSession.user.profileImageSource(
                        client: viewModel.userSession.client
                    )
                ) {
                    isPhotoPickerPresented.wrappedValue = true
                } onDelete: {
                    profileImageViewModel.delete()
                }
                .photoPicker(
                    isPresented: isPhotoPickerPresented,
                    viewModel: profileImageViewModel,
                    presetRatio: .alwaysUsingOnePresetFixedRatio(ratio: 1)
                )
            }

            Section {
                ChevronButton(L10n.quickConnect) {
                    router.route(to: .quickConnectAuthorize(user: viewModel.userSession.user.data))
                }

                ChevronButton(L10n.password) {
                    router.route(to: .resetUserPassword(userID: viewModel.userSession.user.id))
                }
            }
            #endif

            Section {
                ChevronButton(L10n.security) {
                    router.route(to: .localUserSecurity)
                }
            }

            Section {
                // TODO: Disabled as non-essential stored values and
                // settings need to be migrated to be separate
                StateAdapter(initialValue: false) { isPresentingConfirmReset in
                    Button(L10n.resetSettings, role: .destructive) {
                        isPresentingConfirmReset.wrappedValue = true
                    }
                    .confirmationDialog(
                        L10n.resetSettings,
                        isPresented: isPresentingConfirmReset,
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
            } footer: {
                Text(L10n.resetSettingsDescription)
            }
        } image: {
            UserProfileImage(
                userID: viewModel.userSession.user.id,
                source: viewModel.userSession.user.profileImageSource(
                    client: viewModel.userSession.client
                )
            )
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
        }
        .navigationTitle(L10n.user)
    }
}
