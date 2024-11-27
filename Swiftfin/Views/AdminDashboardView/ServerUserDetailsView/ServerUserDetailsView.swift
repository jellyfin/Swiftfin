//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserDetailsView: View {

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @CurrentDate
    private var currentDate: Date

    @StateObject
    private var viewModel: ServerUserAdminViewModel

    @State
    private var isPresentingUsernameEditor: Bool = false
    @State
    private var isPresentingProfileImageOptions: Bool = false

    @State
    private var tempUsername: String

    // MARK: - Initializer

    init(user: UserDto) {
        _viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
        tempUsername = user.name ?? ""
    }

    // MARK: - Body

    var body: some View {
        List {
            UserProfileImagePicker.ProfileImageSection(
                imageSource: viewModel.user.profileImageSource(
                    client: viewModel.userSession.client,
                    maxWidth: 120
                ),
                username: viewModel.user.name ?? L10n.unknown
            ) {
                isPresentingProfileImageOptions = true
            }

            Section {
                ChevronButton(L10n.password)
                    .onSelect {
                        router.route(to: \.resetUserPassword, viewModel.user.id!)
                    }
                ChevronButton(L10n.permissions)
                    .onSelect {
                        router.route(to: \.userPermissions, viewModel)
                    }

                // TODO: Access: enabledFolders & enableAllFolders

                // TODO: Deletion: enableContentDeletion & enableContentDeletionFromFolders

                // TODO: Parental: accessSchedules, maxParentalRating, blockUnratedItems, blockedTags, blockUnratedItems & blockedMediaFolders

                // TODO: Live TV: enabledChannels & enableAllChannels
            }
        }
        .navigationTitle(L10n.user)
        .onAppear {
            viewModel.send(.loadDetails)
        }
        .onChange(of: viewModel.user.name!) { name in
            tempUsername = name
        }
        .confirmationDialog(
            L10n.user,
            isPresented: $isPresentingProfileImageOptions,
            titleVisibility: .visible
        ) {
            Button(L10n.username) {
                isPresentingUsernameEditor = true
            }
            Button(L10n.selectImage) {
                router.route(to: \.photoPicker, viewModel.user.id!)
            }
            Button(L10n.delete, role: .destructive) {
                viewModel.send(.deleteProfileImage)
            }
        }
        .alert(L10n.username, isPresented: $isPresentingUsernameEditor) {
            TextField(L10n.username, text: $tempUsername)
            Button(L10n.cancel, role: .cancel) {
                tempUsername = viewModel.user.name ?? ""
                isPresentingUsernameEditor = false
            }
            Button(L10n.save) {
                viewModel.send(.updateUsername(tempUsername))
                tempUsername = ""
                isPresentingUsernameEditor = false
            }
        } message: {
            Text(L10n.editUsernameMessage)
        }
    }
}
