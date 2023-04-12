//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

struct ConnectToServerView: View {

    @EnvironmentObject
    private var router: ConnectToServerCoodinator.Router

    @ObservedObject
    var viewModel: ConnectToServerViewModel

    @State
    private var connectionError: Error?
    @State
    private var connectionTask: Task<Void, Never>?
    @State
    private var duplicateServer: (server: ServerState, url: URL)?
    @State
    private var isConnecting: Bool = false
    @State
    private var isPresentingConnectionError: Bool = false
    @State
    private var isPresentingDuplicateServerAlert: Bool = false
    @State
    private var isPresentingError: Bool = false
    @State
    private var url = "http://"

    private func connectToServer() {
        let task = Task {
            isConnecting = true
            connectionError = nil

            do {
                let serverConnection = try await viewModel.connectToServer(url: url)

                if viewModel.isDuplicate(server: serverConnection.server) {
                    duplicateServer = serverConnection
                    isPresentingDuplicateServerAlert = true
                } else {
                    try viewModel.save(server: serverConnection.server)
                    router.route(to: \.userSignIn, serverConnection.server)
                }
            } catch {
                connectionError = error
                isPresentingConnectionError = true
            }

            isConnecting = false
        }

        connectionTask = task
    }

    @ViewBuilder
    private var connectSection: some View {
        Section {
            TextField(L10n.serverURL, text: $url)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .keyboardType(.URL)

            if isConnecting {
                Button(role: .destructive) {
                    connectionTask?.cancel()
                    isConnecting = false
                } label: {
                    L10n.cancel.text
                }
            } else {
                Button {
                    connectToServer()
                } label: {
                    L10n.connect.text
                }
                .disabled(URL(string: url) == nil || isConnecting)
            }
        } header: {
            L10n.connectToJellyfinServer.text
        }
    }

    @ViewBuilder
    private var publicServerSection: some View {
        Section {
            if viewModel.isSearching {
                L10n.searchingDots.text
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                if viewModel.discoveredServers.isEmpty {
                    L10n.noLocalServersFound.text
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.discoveredServers, id: \.id) { server in
                        Button {
                            url = server.currentURL.absoluteString
                            connectToServer()
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(server.name)
                                    .font(.title3)

                                Text(server.currentURL.absoluteString)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(isConnecting)
                    }
                }
            }
        } header: {
            HStack {
                L10n.localServers.text
                Spacer()

                Button {
                    viewModel.discoverServers()
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                }
                .disabled(viewModel.isSearching || isConnecting)
            }
        }
        .headerProminence(.increased)
    }

    var body: some View {
        List {

            connectSection

            publicServerSection
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingConnectionError
        ) {
            Button(L10n.dismiss, role: .cancel)
        } message: {
            Text(connectionError?.localizedDescription ?? .emptyDash)
        }
        .alert(
            L10n.existingServer,
            isPresented: $isPresentingDuplicateServerAlert
        ) {
            Button {
                guard let duplicateServer else { return }
                viewModel.add(
                    url: duplicateServer.url,
                    server: duplicateServer.server
                )
                router.dismissCoordinator()
            } label: {
                L10n.addURL.text
            }

            Button(L10n.dismiss, role: .cancel)
        } message: {
            if let duplicateServer {
                L10n.serverAlreadyExistsPrompt(duplicateServer.server.name).text
            }
        }
        .navigationTitle(L10n.connect)
        .onAppear {
            viewModel.discoverServers()
        }
        .onDisappear {
            isConnecting = false
        }
    }
}
