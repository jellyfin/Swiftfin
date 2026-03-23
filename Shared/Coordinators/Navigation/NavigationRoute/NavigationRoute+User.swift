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

    static let connectToServer = NavigationRoute(
        id: "connectToServer",
        style: .sheet
    ) {
        ConnectToServerView()
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
    // TODO: rename to `localUserAccessPolicy`
    static func userSecurity(pinHint: Binding<String>, accessPolicy: Binding<UserAccessPolicy>) -> NavigationRoute {
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
                WithQuickConnect {
                    UserSignInView(server: server)
                }
            }
        }
    }
}
