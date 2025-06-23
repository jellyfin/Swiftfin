//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    static let connectToServer = NavigationRoute(
        id: "connectToServer",
        style: .sheet
    ) {
        ConnectToServerView()
    }

    static func editServerFromSelectUser(server: ServerState) -> NavigationRoute {
        NavigationRoute(
            id: "editServerFromSelectUser",
            style: .sheet
        ) {
            EditServerView(server: server)
                .environment(\.isEditing, true)
        }
    }

    static func quickConnect(quickConnect: QuickConnect) -> NavigationRoute {
        NavigationRoute(
            id: "quickConnectView",
            style: .sheet
        ) {
            QuickConnectView(quickConnect: quickConnect)
        }
    }

    #if os(iOS)
    static func userProfileImage(viewModel: UserProfileImageViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userProfileImage",
            style: .sheet
        ) {
            UserProfileImagePickerView(viewModel: viewModel)
        }
    }

    static func userProfileImageCrop(viewModel: UserProfileImageViewModel, image: UIImage) -> NavigationRoute {
        NavigationRoute(
            id: "cropImage",
            style: .sheet
        ) {
            UserProfileImageCropView(
                viewModel: viewModel,
                image: image
            )
        }
    }

    static func userSecurity(pinHint: Binding<String>, accessPolicy: Binding<UserAccessPolicy>) -> NavigationRoute {
        NavigationRoute(
            id: "userSecurity",
            style: .sheet
        ) {
            UserSignInView.SecurityView(
                pinHint: pinHint,
                accessPolicy: accessPolicy
            )
        }
    }
    #endif

    static func userSignIn(server: ServerState) -> NavigationRoute {
        NavigationRoute(
            id: "userSignIn",
            style: .sheet
        ) {
            UserSignInView(server: server)
        }
    }
}
