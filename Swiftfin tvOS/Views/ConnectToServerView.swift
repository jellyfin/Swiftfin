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

    private func connectToServer(at url: String) {
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
    private var connectForm: some View {
        VStack(alignment: .leading) {

            L10n.connectToJellyfinServer.text

            TextField(L10n.serverURL, text: $url)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .keyboardType(.URL)

            if isConnecting {
                Button {
                    connectionTask?.cancel()
                    isConnecting = false
                } label: {
                    L10n.cancel.text
                        .foregroundColor(.red)
                        .bold()
                        .font(.callout)
                        .frame(height: 75)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.card)
            } else {
                Button {
                    connectToServer(at: url)
                } label: {
                    L10n.connect.text
                        .bold()
                        .font(.callout)
                        .frame(height: 75)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isConnecting || url.isEmpty {
                                Color.secondary
                            } else {
                                Color.jellyfinPurple
                            }
                        }
                }
                .disabled(isConnecting || url.isEmpty)
                .buttonStyle(.card)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var searchingDiscoverServers: some View {
        HStack(spacing: 5) {
            ProgressView()

            L10n.searchingDots.text
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var noLocalServersFound: some View {
        L10n.noLocalServersFound.text
            .font(.callout)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var publicServers: some View {
        VStack(alignment: .center) {

            HStack {
                L10n.localServers.text
                    .font(.title3)
                    .fontWeight(.semibold)

                SFSymbolButton(systemName: "arrow.clockwise")
                    .onSelect {
                        viewModel.discoverServers()
                    }
                    .frame(width: 30, height: 30)
                    .disabled(viewModel.isSearching || viewModel.isLoading)
            }

            if viewModel.isSearching {
                searchingDiscoverServers
                    .frame(maxHeight: .infinity)
            } else if viewModel.discoveredServers.isEmpty {
                noLocalServersFound
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack {
                        ForEach(viewModel.discoveredServers, id: \.id) { server in
                            ServerButton(server: server)
                                .onSelect {
                                    connectToServer(at: server.currentURL.absoluteString)
                                }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            connectForm
                .frame(maxWidth: .infinity)

            publicServers
                .frame(maxWidth: .infinity)
        }
        .navigationTitle(L10n.connect.text)
        .onAppear {
            viewModel.discoverServers()
        }
//        .alert(item: $viewModel.errorMessage) { _ in
//            Alert(
//                title: Text(viewModel.alertTitle),
//                message: Text(viewModel.errorMessage?.message ?? L10n.unknownError),
//                dismissButton: .cancel()
//            )
//        }
//        .alert(item: $viewModel.addServerURIPayload) { _ in
//            Alert(
//                title: L10n.existingServer.text,
//                message: L10n.serverAlreadyExistsPrompt(viewModel.addServerURIPayload?.server.name ?? .emptyDash).text,
//                dismissButton: .cancel()
//            )
//        }
    }
}
