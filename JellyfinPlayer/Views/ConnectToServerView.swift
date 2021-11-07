/*
 * JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Defaults
import Stinsen
import SwiftUI

struct ConnectToServerView: View {
    
    @ObservedObject var viewModel: ConnectToServerViewModel
    @State var uri = ""
    
    @Default(.defaultHTTPScheme) var defaultHTTPScheme
    
    var body: some View {
        List {
            Section {
                TextField(NSLocalizedString("Server URL", comment: ""), text: $uri)
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
                        Text("Cancel")
                    }
                } else {
                    Button {
                        viewModel.connectToServer(uri: uri)
                    } label: {
                        Text("Connect")
                    }
                    .disabled(uri.isEmpty)
                }
            } header: {
                Text("Connect to a Jellyfin server")
            }
            
            Section {
                if viewModel.searching {
                    HStack(alignment: .center, spacing: 5) {
                        Spacer()
                        // Oct. 15, 2021
                        // There is a bug where ProgressView() won't appear sometimes when searching,
                        //     dots were used instead but ProgressView() is preferred
                        Text("Searching...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    if viewModel.discoveredServers.isEmpty {
                        HStack(alignment: .center) {
                            Spacer()
                            Text("No local servers found")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        ForEach(viewModel.discoveredServers.sorted(by: { $0.name < $1.name }), id: \.id) { discoveredServer in
                            Button {
                                uri = discoveredServer.url.absoluteString
                                viewModel.connectToServer(uri: discoveredServer.url.absoluteString)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(discoveredServer.name)
                                        .font(.title3)
                                    Text(discoveredServer.host)
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
                    Text("Local Servers")
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
            Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.errorMessage?.displayMessage ?? "Unknown Error"),
                  dismissButton: .cancel())
        }
        .alert(item: $viewModel.addServerURIPayload) { _ in   
            Alert(title: Text("Existing Server"),
                  message: Text("Server \(viewModel.addServerURIPayload?.server.name ?? "") already exists. Add new URL?"),
                  primaryButton: .default(Text("Add URL"), action: {
                viewModel.addURIToServer(addServerURIPayload: viewModel.backAddServerURIPayload!)
            }),
                  secondaryButton: .cancel())
        }
        .navigationTitle("Connect")
        .onAppear {
            viewModel.discoverServers()
            AppURLHandler.shared.appURLState = .allowedInLogin
        }
        .navigationBarBackButtonHidden(viewModel.isLoading)
    }
}
