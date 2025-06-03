//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserDetailsView: View {

    // MARK: - Current Date

    @CurrentDate
    private var currentDate: Date

    // MARK: - State, Observed, & Environment Objects

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @StateObject
    private var viewModel: ServerUserAdminViewModel

    @StateObject
    private var profileViewModel: UserProfileImageViewModel

    // MARK: - Dialog State

    @State
    private var username: String
    @State
    private var isPresentingUsername = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(user: UserDto) {
        self._viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
        self._profileViewModel = StateObject(wrappedValue: UserProfileImageViewModel(user: user))
        self.username = user.name ?? ""
    }

    // MARK: - Body

    var body: some View {
        List {
            UserProfileHeroImage(
                user: viewModel.user,
                source: viewModel.user.profileImageSource(
                    client: viewModel.userSession.client,
                    maxWidth: 150
                )
            ) {
                router.route(to: \.userPhotoPicker, profileViewModel)
            } onDelete: {
                profileViewModel.send(.delete)
            }

            Section {
                ChevronButton(
                    L10n.username,
                    subtitle: viewModel.user.name
                ) {
                    TextField(L10n.username, text: $username)
                    HStack {
                        Button(L10n.cancel) {
                            username = viewModel.user.name ?? ""
                            isPresentingUsername = false
                        }
                        Button(L10n.save) {
                            viewModel.send(.updateUsername(username))
                            isPresentingUsername = false
                        }
                    }
                }
                ChevronButton(L10n.permissions) {
                    router.route(to: \.userPermissions, viewModel)
                }
                if let userId = viewModel.user.id {
                    ChevronButton(L10n.password) {
                        router.route(to: \.resetUserPassword, userId)
                    }
                    ChevronButton(L10n.quickConnect) {
                        router.route(to: \.quickConnectAuthorize, viewModel.user)
                    }
                }
            }

            Section(L10n.access) {
                ChevronButton(L10n.devices) {
                    router.route(to: \.userDeviceAccess, viewModel)
                }
                ChevronButton(L10n.liveTV) {
                    router.route(to: \.userLiveTVAccess, viewModel)
                }
                ChevronButton(L10n.media) {
                    router.route(to: \.userMediaAccess, viewModel)
                }
            }

            Section(L10n.parentalControls) {
                ChevronButton(L10n.ratings) {
                    router.route(to: \.userParentalRatings, viewModel)
                }
                ChevronButton(L10n.accessSchedules) {
                    router.route(to: \.userEditAccessSchedules, viewModel)
                }
                ChevronButton(L10n.accessTags) {
                    router.route(to: \.userEditAccessTags, viewModel)
                }
            }
        }
        .navigationTitle(L10n.user)
        .onAppear {
            viewModel.send(.refresh)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                error = eventError
                username = viewModel.user.name ?? ""
            case .updated:
                break
            }
        }
        .errorMessage($error)
    }
}
