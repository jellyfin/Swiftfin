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

        private let servers: OrderedSet<ServerState>

        private var selectedServer: ServerState? {
            serverSelection.server(from: servers)
        }

        init(
            servers: OrderedSet<ServerState>
        ) {
            self.servers = servers
        }

        var body: some View {
            ConditionalMenu(
                tracking: selectedServer,
                action: { server in
                    router.route(to: .userSignIn(server: server))
                }
            ) {
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
            }
        }
    }

    struct EditUsersMenu: View {

        @Environment(\.editMode)
        private var editMode

        var body: some View {
            Toggle(
                L10n.editUsers,
                systemImage: "person.crop.circle",
                isOn: Binding(
                    get: { editMode?.wrappedValue.isEditing == true },
                    set: { editMode?.wrappedValue = $0 ? .active : .inactive }
                )
            )
        }
    }
}
