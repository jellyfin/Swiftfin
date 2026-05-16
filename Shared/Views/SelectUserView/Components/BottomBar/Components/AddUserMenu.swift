//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct AddUserMenu: View {

        @Default(.selectUserServerSelection)
        private var serverSelection

        @Router
        private var router

        let servers: OrderedSet<ServerState>

        var body: some View {
            ConditionalMenu(tracking: serverSelection.server(from: servers)) { server in
                router.route(to: .userSignIn(server: server))
            } menuContent: {
                ForEach(servers) { server in
                    Button {
                        router.route(to: .userSignIn(server: server))
                    } label: {
                        Text(server.name)
                        Text(server.currentURL.absoluteString)
                    }
                }
            } label: {
                Label(L10n.addUser, systemImage: "plus")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .fontWeight(.bold)
            }
        }
    }
}
