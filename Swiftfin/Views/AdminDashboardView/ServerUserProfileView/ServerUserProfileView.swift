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

struct ServerUserProfileView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @ObservedObject
    var viewModel: ServerUserAdminViewModel

    @State
    private var isPresentingProfileImageOptions: Bool = false

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
            }
        }
        .confirmationDialog(
            "Profile Image",
            isPresented: $isPresentingProfileImageOptions,
            titleVisibility: .visible
        ) {

            Button("Select Image") {
                router.route(to: \.photoPicker, viewModel.user.id!)
            }

            Button(L10n.delete, role: .destructive) {
                viewModel.deleteCurrentUserProfileImage()
            }
        }
    }
}
