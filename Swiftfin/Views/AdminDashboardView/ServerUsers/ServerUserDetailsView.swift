//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import JellyfinAPI
import Mantis
import SwiftUI

struct ServerUserDetailsView: View {

    @CurrentDate
    private var currentDate: Date

    @Router
    private var router

    @StateObject
    private var viewModel: ServerUserAdminViewModel
    @StateObject
    private var profileViewModel: UserImageViewModel

    init(user: UserDto) {
        self._viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
        self._profileViewModel = StateObject(wrappedValue: UserImageViewModel(user: user))
    }

    var body: some View {
        List {
            StateAdapter(initialValue: false) { isPhotoPickerPresented in
                UserProfileHeroImage(
                    user: viewModel.user,
                    source: viewModel.user.profileImageSource(
                        client: viewModel.userSession.client,
                        maxWidth: 150
                    )
                ) {
                    isPhotoPickerPresented.wrappedValue = true
                } onDelete: {
                    profileViewModel.delete()
                }
                .photoPicker(
                    isPresented: isPhotoPickerPresented,
                    isSaving: profileViewModel.background.is(.updating),
                    presetRatio: .alwaysUsingOnePresetFixedRatio(ratio: 1),
                    onSave: profileViewModel.upload
                )
                .onReceive(profileViewModel.events) { event in
                    switch event {
                    case .updated:
                        UIDevice.feedback(.success)
                        isPhotoPickerPresented.wrappedValue = false
                    case .deleted:
                        UIDevice.feedback(.success)
                    }
                }
            }

            Section {
                StateAdapter(initialValue: (isPresented: false, username: viewModel.user.name ?? "")) { alert in
                    ChevronButton(L10n.username) {
                        alert.isPresented.wrappedValue = true
                    }
                    .alert(L10n.username, isPresented: alert.isPresented) {
                        TextField(L10n.username, text: alert.username)

                        Button(L10n.save) {
                            viewModel.updateUsername(alert.username.wrappedValue)
                        }

                        Button(L10n.cancel, role: .cancel) {
                            alert.username.wrappedValue = viewModel.user.name ?? ""
                        }
                    }
                }

                ChevronButton(L10n.permissions) {
                    router.route(to: .userPermissions(viewModel: viewModel))
                }

                if let userId = viewModel.user.id {
                    ChevronButton(L10n.password) {
                        router.route(to: .resetUserPasswordAdmin(userID: userId))
                    }

                    ChevronButton(L10n.quickConnect) {
                        router.route(to: .quickConnectAuthorize(user: viewModel.user))
                    }
                }
            }

            Section(L10n.access) {
                ChevronButton(L10n.devices) {
                    router.route(to: .userDeviceAccess(viewModel: viewModel))
                }

                ChevronButton(L10n.liveTV) {
                    router.route(to: .userLiveTVAccess(viewModel: viewModel))
                }

                ChevronButton(L10n.media) {
                    router.route(to: .userMediaAccess(viewModel: viewModel))
                }
            }

            Section(L10n.parentalControls) {
                ChevronButton(L10n.parentalRatings) {
                    router.route(to: .userParentalRatings(viewModel: viewModel))
                }

                ChevronButton(L10n.accessSchedules) {
                    router.route(to: .userEditAccessSchedules(viewModel: viewModel))
                }

                ChevronButton(L10n.accessTags) {
                    router.route(to: .userEditAccessTags(viewModel: viewModel))
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.user)
        .topBarTrailing {
            if viewModel.background.is(.updating) || viewModel.background.is(.refreshing) {
                ProgressView()
            }
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .refreshable {
            viewModel.refresh()
        }
        .errorMessage($viewModel.error) {
            UIDevice.feedback(.error)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
            }
        }
    }
}
