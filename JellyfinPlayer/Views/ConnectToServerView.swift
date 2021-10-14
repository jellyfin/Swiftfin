/*
 * JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import Stinsen

struct ConnectToServerView: View {
    
    @StateObject var viewModel: ConnectToServerViewModel
    @State var uri = ""
    
    var body: some View {
        List {
            Section {
                TextField(NSLocalizedString("Server URL", comment: ""), text: $uri)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                Button {
                    viewModel.connectToServer(uri: uri)
                } label: {
                    HStack {
                        Text("Connect")
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isLoading || uri.isEmpty)
            } header: {
                Text("Connect to a Jellyfin server")
            }
            
            Section(header: Text("Local Servers")) {
                if viewModel.searching {
                    ProgressView()
                }
                ForEach(viewModel.discoveredServers.sorted(by: { $0.name < $1.name }), id: \.id) { discoveredServer in
                    Button(action: {
                        viewModel.connectToServer(uri: discoveredServer.url.absoluteString)
                    }, label: {
                        HStack {
                            Text(discoveredServer.name)
                                .font(.headline)
                            Text("• \(discoveredServer.host)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            }
                        }

                    })
                }
            }
            .onAppear(perform: self.viewModel.discoverServers)
            .headerProminence(.increased)
        }
        .alert(item: $viewModel.errorMessage) { _ in
            Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.errorMessage?.displayMessage ?? "Unknown Error"),
                  dismissButton: .cancel())
        }
        .navigationTitle("Connect")
        .onAppear {
            AppURLHandler.shared.appURLState = .allowedInLogin
        }
    }
}
