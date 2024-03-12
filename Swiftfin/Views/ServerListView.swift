//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import SwiftUI

struct ServerListView: View {

    @EnvironmentObject
    private var router: ServerListCoordinator.Router

    @ObservedObject
    var viewModel: ServerListViewModel

    private var listView: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.servers, id: \.id) { server in
                    Button {
                        router.route(to: \.userList, server)
                    } label: {
                        ZStack(alignment: Alignment.leading) {
                            Rectangle()
                                .foregroundColor(Color(UIColor.secondarySystemFill))
                                .cornerRadius(10)

                            HStack(spacing: 10) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 36))
                                    .foregroundColor(.primary)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(server.name)
                                        .font(.title2)
                                        .foregroundColor(.primary)

                                    Text(server.currentURL.absoluteString)
                                        .font(.footnote)
                                        .disabled(true)
                                        .foregroundColor(.secondary)

                                    Text(viewModel.userTextFor(server: server))
                                        .font(.footnote)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                        }
                    }
                    .padding()
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.remove(server: server)
                        } label: {
                            Label(L10n.remove, systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var noServerView: some View {
        VStack {
            L10n.connectToJellyfinServerStart.text
                .frame(minWidth: 50, maxWidth: 240)
                .multilineTextAlignment(.center)

            PrimaryButton(title: L10n.connect)
                .onSelect {
                    router.route(to: \.connectToServer)
                }
                .frame(maxWidth: 300)
                .frame(height: 50)
        }
    }

    @ViewBuilder
    private var innerBody: some View {
        if viewModel.servers.isEmpty {
            noServerView
                .offset(y: -50)
        } else {
            listView
        }
    }

    @ViewBuilder
    private var trailingToolbarContent: some View {
        if viewModel.servers.isNotEmpty {
            Button {
                router.route(to: \.connectToServer)
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
    }

    @ViewBuilder
    private var leadingToolbarContent: some View {
        Button {
            router.route(to: \.basicAppSettings)
        } label: {
            Image(systemName: "gearshape.fill")
                .accessibilityLabel(L10n.settings)
        }
    }

    var body: some View {
        innerBody
            .navigationTitle(L10n.servers)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    trailingToolbarContent
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    leadingToolbarContent
                }
            }
            .onAppear {
                viewModel.fetchServers()
            }
    }
}
