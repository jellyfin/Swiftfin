/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import JellyfinAPI
import SwiftUI

struct ConnectToServerView: View {
    @StateObject var viewModel = ConnectToServerViewModel()
    @State var username = ""
    @State var password = ""
    @State var uri = ""

    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.isConnectedServer {
                    Section(header: Text(viewModel.lastPublicUsers.isEmpty || username == "" ? "Login to \(SessionManager.main.currentLogin.server.name)": "")) {
                        if viewModel.lastPublicUsers.isEmpty || username == "" {
                            TextField(NSLocalizedString("Username", comment: ""), text: $username)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                        } else {
                            HStack {
                                Spacer()
                                ImageView(src: URL(string: "\(SessionManager.main.currentLogin.server.uri)/Users/\(viewModel.selectedPublicUser.id ?? "")/Images/Primary?width=500&quality=80&tag=\(viewModel.selectedPublicUser.primaryImageTag ?? "")")!)
                                    .frame(width: 250, height: 250)
                                    .cornerRadius(125.0)
                                Spacer()
                            }
                        }

                        SecureField(NSLocalizedString("Password", comment: ""), text: $password)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }

                    Section {
                        HStack {
                            Button {
                                if !viewModel.lastPublicUsers.isEmpty {
                                    username = ""
                                    viewModel.showPublicUsers()
                                } else {
                                    viewModel.isConnectedServer = false
                                }
                            } label: {
                                Spacer()
                                HStack {
                                    Text("Back")
                                }
                                Spacer()
                            }

                            Button {
                                viewModel.login()
                            } label: {
                                Spacer()
                                if viewModel.isLoading {
                                    ProgressView()
                                } else {
                                    Text("Login")
                                }
                                Spacer()
                            }.disabled(viewModel.isLoading || username.isEmpty)
                        }
                    }
                }
            } else {
                if !viewModel.isLoading {

                    Form {
                        Section(header: Text("Server Information")) {
                            TextField(NSLocalizedString("Server URL", comment: ""), text: $uri)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                            Button {
                                viewModel.connectToServer()
                            } label: {
                                HStack {
                                    Text("Connect")
                                    Spacer()
                                }
                                if viewModel.isLoading {
                                    ProgressView()
                                }
                            }
                            .disabled(viewModel.isLoading || uri.isEmpty)
                        }
                        Section(header: Text("Local Servers")) {
                            if self.viewModel.searching {
                                ProgressView()
                            }
                            ForEach(self.viewModel.servers, id: \.id) { server in
                                Button(action: {
                                    print(server.url)
                                    viewModel.connectToServer(at: server.url)
                                }, label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(server.name)
                                                .font(.headline)
                                            Text(server.host)
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.forward")
                                            .padding()
                                    }

                                })
                                .disabled(viewModel.isLoading)
                            }
                        }
                        .onAppear(perform: self.viewModel.discoverServers)
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .padding(.leading, 90)
        .padding(.trailing, 90)
        .alert(item: $viewModel.errorMessage) { _ in
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage as? String ?? ""), dismissButton: .default(Text("Ok")))
        }
        .onChange(of: uri) { uri in
            viewModel.uriSubject.send(uri)
        }
        .onChange(of: username) { username in
            viewModel.usernameSubject.send(username)
        }
        .onChange(of: password) { password in
            viewModel.passwordSubject.send(password)
        }
        .navigationTitle(viewModel.isConnectedServer ? NSLocalizedString("Who's watching?", comment: "") : NSLocalizedString("Connect to Jellyfin", comment: ""))
    }
}
