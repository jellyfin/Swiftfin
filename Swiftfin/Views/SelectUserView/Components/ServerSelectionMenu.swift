//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct ServerSelectionMenu: View {

        @EnvironmentObject
        private var router: UserListCoordinator.Router

        @Binding
        private var serverSelection: ServerSelection

        @ObservedObject
        private var viewModel: SelectUserViewModel

        private var selectedServer: ServerState? {
            if case let ServerSelection.server(id: id) = serverSelection,
               let server = viewModel.servers.keys.first(where: { server in server.id == id })
            {
                return server
            }

            return nil
        }

        init(
            selection: Binding<ServerSelection>,
            viewModel: SelectUserViewModel
        ) {
            self._serverSelection = selection
            self.viewModel = viewModel
        }

        var body: some View {
            Menu {
                Section {
                    Button("Add Server", systemImage: "plus") {
                        router.route(to: \.connectToServer)
                    }

                    if let selectedServer {
                        Button("Edit Server", systemImage: "server.rack") {
                            router.route(to: \.editServer, selectedServer)
                        }
                    }
                }

                Picker("Servers", selection: _serverSelection) {

                    if viewModel.servers.keys.count > 1 {
                        Label("All Servers", systemImage: "person.2.fill")
                            .tag(ServerSelection.all)
                    }

                    ForEach(viewModel.servers.keys) { server in
                        Button {
                            Text(server.name)
                            Text(server.currentURL.absoluteString)
                        }
                        .tag(ServerSelection.server(id: server.id))
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(Color.tertiarySystemBackgorund)

                    Group {
                        switch serverSelection {
                        case .all:
                            Label("All Servers", systemImage: "person.2.fill")
                        case let .server(id):
                            if let server = viewModel.servers.keys.first(where: { $0.id == id }) {
                                Label(server.name, systemImage: "server.rack")
                            }
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                }
                .frame(height: 50)
            }
            .buttonStyle(.plain)
        }
    }
}
