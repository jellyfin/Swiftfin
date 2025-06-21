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
        routeType: .sheet
    ) {
        ConnectToServerView()
    }

    static func editServerFromSelectUser(server: ServerState) -> NavigationRoute {
        NavigationRoute(
            id: "editServerFromSelectUser",
            routeType: .sheet
        ) {
            EditServerView(server: server)
                .environment(\.isEditing, true)
        }
    }

    static func quickConnect(quickConnect: QuickConnect) -> NavigationRoute {
        NavigationRoute(
            id: "quickConnectView",
            routeType: .sheet
        ) {
            QuickConnectView(quickConnect: quickConnect)
        }
    }

    static let selectUser = NavigationRoute(
        id: "selectUser"
    ) {
        SelectUserView()
    }

    #if !os(tvOS)
    static func userProfileImage(viewModel: UserProfileImageViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userProfileImage",
            routeType: .sheet
        ) {
            UserProfileImagePickerView()
//            UserProfileImageView(viewModel: viewModel)
        }
    }

    static func userSecurity(pinHint: Binding<String>, accessPolicy: Binding<UserAccessPolicy>) -> NavigationRoute {
        NavigationRoute(
            id: "userSecurity",
            routeType: .sheet
        ) {
            UserSignInView.SecurityView(
                pinHint: pinHint,
                accessPolicy: accessPolicy
            )
        }
    }
    #endif

    static func userSignIn(server: ServerState) -> NavigationRoute {
        NavigationRoute(id: "userSignIn") {
            UserSignInView(server: server)
        }
    }
}
