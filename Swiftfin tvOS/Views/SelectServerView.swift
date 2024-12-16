//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import SwiftUI

struct SelectServerView: View {

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @Binding
    private var serverSelection: SelectUserServerSelection

    @ObservedObject
    private var viewModel: SelectUserViewModel

    private var selectedServer: ServerState? {
        if case let SelectUserServerSelection.server(id: id) = serverSelection,
           let server = viewModel.servers.keys.first(where: { server in server.id == id })
        {
            return server
        }

        return nil
    }

    init(
        selection: Binding<SelectUserServerSelection>,
        viewModel: SelectUserViewModel
    ) {
        self._serverSelection = selection
        self.viewModel = viewModel
    }

    var body: some View {
        FullScreenMenu(L10n.servers) {
            Section {
                Button {
                    router.popLast {
                        router.route(to: \.connectToServer)
                    }
                } label: {
                    HStack {
                        L10n.addServer.text
                            .font(.headline)

                        Spacer()

                        Image(systemName: "plus")
                    }
                    .padding()
                }
                .buttonStyle(.card)

                if let selectedServer {
                    Button {
                        router.popLast {
                            router.route(to: \.editServer, selectedServer)
                        }
                    } label: {
                        HStack {
                            L10n.editServer.text
                                .font(.headline)

                            Spacer()

                            Image(systemName: "server.rack")
                        }
                        .padding()
                    }
                    .buttonStyle(.card)
                }
            }

            Section(L10n.selectedServer) {

                if viewModel.servers.keys.count > 1 {
                    Button {
                        serverSelection = .all
                        router.popLast()
                    } label: {
                        HStack {
                            L10n.allServers.text
                                .font(.headline)

                            Spacer()

                            if serverSelection == .all {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding()
                    }
                    .buttonStyle(.card)
                }

                Form {
                    ForEach(viewModel.servers.keys.reversed()) { server in
                        Button {
                            serverSelection = .server(id: server.id)
                            router.popLast()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(server.name)
                                        .lineLimit(1)
                                        .font(.headline)

                                    Text(server.currentURL.absoluteString)
                                        .lineLimit(1)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedServer == server {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                        }
                    }
                }
                .padding(0)
                .scrollClipDisabled()
            }
            .padding(.top)
            .headerProminence(.increased)
        }
    }
}
