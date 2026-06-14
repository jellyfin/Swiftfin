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

    @StateObject
    private var imageViewModel: UserImageViewModel

    init(user: UserDto) {
        self._imageViewModel = StateObject(wrappedValue: UserImageViewModel(user: user))
    }

    var body: some View {
        Form {
            #if os(iOS)
            if let userSession = imageViewModel.userSession {
                StateAdapter(initialValue: false) { isPhotoPickerPresented in
                    UserProfileHeroImage(
                        user: imageViewModel.user,
                        source: userSession.user.profileImageSource(
                            client: userSession.client
                        )
                    ) {
                        isPhotoPickerPresented.wrappedValue = true
                    } onDelete: {
                        imageViewModel.delete()
                    }
                    .photoPicker(
                        isPresented: isPhotoPickerPresented,
                        isSaving: imageViewModel.background.is(.updating),
                        presetRatio: .alwaysUsingOnePresetFixedRatio(ratio: 1)
                    ) {
                        imageViewModel.upload($0)
                    }
                    .onReceive(imageViewModel.events) { event in
                        switch event {
                        case .updated:
                            UIDevice.feedback(.success)
                            isPhotoPickerPresented.wrappedValue = false
                        case .deleted:
                            UIDevice.feedback(.success)
                        }
                    }
                }
            }

            if let userSession = imageViewModel.userSession {
                Section {
                    ChevronButton(L10n.quickConnect) {
                        router.route(to: .quickConnectAuthorize(user: userSession.user.data))
                    }

                    ChevronButton(L10n.password) {
                        router.route(to: .resetUserPassword(userID: userSession.user.id))
                    }
                }
            }
            #endif

            Section {
                ChevronButton(L10n.security) {
                    router.route(to: .localUserSecurity)
                }
            }

            // TODO: Disabled as stored values and defaults
            // settings need to be migrated to final destinations
//            StateAdapter(initialValue: false) { isPresented in
//                Section {
//                    Button(L10n.resetSettings, role: .destructive) {
//                        isPresented.wrappedValue = true
//                    }
//                } footer: {
//                    Text(L10n.resetSettingsDescription)
//                }
//                .confirmationDialog(
//                    L10n.resetSettings,
//                    isPresented: isPresented,
//                    titleVisibility: .visible
//                ) {
//                    Button(L10n.reset, role: .destructive) {
//                        do {
//                            try viewModel.userSession.user.deleteSettings()
//                        } catch {
//                            viewModel.logger.error("Unable to reset user settings: \(error.localizedDescription)")
//                        }
//                    }
//                } message: {
//                    Text(L10n.resetSettingsMessage)
//                }
//            }
        } image: {
            if let userSession = imageViewModel.userSession {
                UserProfileImage(
                    userID: userSession.user.id,
                    source: userSession.user.profileImageSource(
                        client: userSession.client
                    )
                )
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)
            }
        }
        .navigationTitle(L10n.user)
        .errorMessage($imageViewModel.error)
    }
}
