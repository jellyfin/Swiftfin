//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    static var connectToServer: NavigationRoute {
        NavigationRoute(
            id: "connectToServer",
            style: .sheet
        ) {
            #if os(tvOS)
            NativeConnectToServerView()
            #else
            ConnectToServerView()
            #endif
        }
    }

    static func quickConnect(client: JellyfinClient, action: @escaping (String) async -> Void) -> NavigationRoute {
        NavigationRoute(
            id: "quickConnectView",
            style: .sheet
        ) {
            QuickConnectView(client: client, action: action)
        }
    }

    #if os(iOS)
    // TODO: rename to `localUserAccessPolicy`
    static func userSecurity(pinHint: Binding<String>, accessPolicy: Binding<LocalUserAccessPolicy>) -> NavigationRoute {
        NavigationRoute(
            id: "userSecurity",
            style: .sheet
        ) {
            LocalUserAccessPolicyView(
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
            WithUserAuthentication {
                #if os(tvOS)
                NativeUserSignInView(server: server)
                #else
                UserSignInView(server: server)
                #endif
            }
        }
    }
}
