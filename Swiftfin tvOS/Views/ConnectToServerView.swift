//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

struct ConnectToServerView: View {

    @ObservedObject
    var viewModel: ConnectToServerViewModel
    @State
    private var uri = ""

    @Default(.defaultHTTPScheme)
    private var defaultHTTPScheme

    @ViewBuilder
    private var connectForm: some View {
        VStack(alignment: .leading) {
            Section {
                TextField(L10n.serverURL, text: $uri)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .onAppear {
                        if uri == "" {
                            uri = "\(defaultHTTPScheme.rawValue)://"
                        }
                    }

                Button {
                    viewModel.connectToServer(uri: uri)
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                        }

                        L10n.connect.text
                            .bold()
                            .font(.callout)
                    }
                    .frame(height: 75)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isLoading || uri.isEmpty ? .secondary : Color.jellyfinPurple)
                }
                .disabled(viewModel.isLoading || uri.isEmpty)
                .buttonStyle(.plain)
            } header: {
                L10n.connectToJellyfinServer.text
            }
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
    private var localServers: some View {
        VStack(alignment: .center) {

            HStack {
                L10n.localServers.text
                    .font(.title3)
                    .fontWeight(.semibold)

                SFSymbolButton(systemName: "arrow.clockwise") {
                    viewModel.discoverServers()
                }
                .frame(width: 30, height: 30)
                .disabled(viewModel.searching || viewModel.isLoading)
            }

            if viewModel.searching {
                searchingDiscoverServers
                    .frame(maxHeight: .infinity)
            } else {
                if viewModel.discoveredServers.isEmpty {
                    noLocalServersFound
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.discoveredServers, id: \.self) { server in
                                ServerButton(server: server)
                                    .onSelect {
                                        viewModel.connectToServer(uri: server.currentURI)
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            connectForm
                .frame(maxWidth: .infinity)

            localServers
                .frame(maxWidth: .infinity)
        }
        .navigationTitle(L10n.connect.text)
        .onAppear {
            viewModel.discoverServers()
        }
        .alert(item: $viewModel.errorMessage) { _ in
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.errorMessage?.message ?? L10n.unknownError),
                dismissButton: .cancel()
            )
        }
        .alert(item: $viewModel.addServerURIPayload) { _ in
            Alert(
                title: L10n.existingServer.text,
                message: L10n.serverAlreadyExistsPrompt(viewModel.addServerURIPayload?.server.name ?? .emptyDash).text,
                dismissButton: .cancel()
            )
        }
    }
}
