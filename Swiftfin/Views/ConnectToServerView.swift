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
    var uri = ""

    @Default(.defaultHTTPScheme)
    var defaultHTTPScheme

    var body: some View {
        List {
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

                if viewModel.isLoading {
                    Button(role: .destructive) {
                        viewModel.cancelConnection()
                    } label: {
                        L10n.cancel.text
                    }
                } else {
                    Button {
                        viewModel.connectToServer(uri: uri)
                    } label: {
                        HStack {
                            L10n.connect.text

                            Spacer()

                            if viewModel.isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(uri.isEmpty || viewModel.isLoading)
                }
            } header: {
                L10n.connectToJellyfinServer.text
            }

            Section {
                if viewModel.searching {
                    HStack(alignment: .center, spacing: 5) {
                        Spacer()
                        L10n.searchingDots.text
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    if viewModel.discoveredServers.isEmpty {
                        HStack(alignment: .center) {
                            Spacer()
                            L10n.noLocalServersFound.text
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        ForEach(viewModel.discoveredServers, id: \.id) { server in
                            Button {
                                uri = server.currentURI
                                viewModel.connectToServer(uri: server.currentURI)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(server.name)
                                        .font(.title3)
                                    Text(server.currentURI)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .disabled(viewModel.isLoading)
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
                    .disabled(viewModel.searching || viewModel.isLoading)
                }
            }
            .headerProminence(.increased)
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
                message: L10n.serverAlreadyExistsPrompt(viewModel.addServerURIPayload?.server.name ?? "").text,
                primaryButton: .default(L10n.addURL.text, action: {
                    viewModel.addURIToServer(addServerURIPayload: viewModel.backAddServerURIPayload!)
                }),
                secondaryButton: .cancel()
            )
        }
        .navigationTitle(L10n.connect)
        .onAppear {
            viewModel.discoverServers()
            AppURLHandler.shared.appURLState = .allowedInLogin
        }
        .navigationBarBackButtonHidden(viewModel.isLoading)
    }
}
