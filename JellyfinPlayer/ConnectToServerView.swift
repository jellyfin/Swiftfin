/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

struct ConnectToServerView: View {
    @StateObject var viewModel = ConnectToServerViewModel()
    @State var username = ""
    @State var password = ""
    @State var uri = ""

    var body: some View {
        ZStack {
            Form {
                if viewModel.isConnectedServer {
                    if viewModel.publicUsers.isEmpty {
                        Section(header: Text("Login to \(ServerEnvironment.current.server.name ?? "")")) {
                            TextField(NSLocalizedString("Username", comment: ""), text: $username)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                            SecureField(NSLocalizedString("Password", comment: ""), text: $password)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                            Button {
                                viewModel.login()
                            } label: {
                                HStack {
                                    Text("Login")
                                    Spacer()
                                    if viewModel.isLoading {
                                        ProgressView()
                                    }
                                }
                            }.disabled(viewModel.isLoading || username.isEmpty)
                        }

                        Section {
                            Button {
                                viewModel.isConnectedServer = false
                            } label: {
                                HStack {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Change Server")
                                    }
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        Section(header: Text("Login to \(ServerEnvironment.current.server.name ?? "")")) {
                            ForEach(viewModel.publicUsers, id: \.id) { publicUser in
                                HStack {
                                    Button(action: {
                                        username = publicUser.name ?? ""
                                        viewModel.publicUsers.removeAll()
                                        if !(publicUser.hasPassword ?? true) {
                                            password = ""
                                            viewModel.login()
                                        }
                                    }) {
                                        HStack {
                                            Text(publicUser.name ?? "").font(.subheadline).fontWeight(.semibold)
                                            Spacer()
                                            if publicUser.primaryImageTag != nil {
                                                ImageView(src: URL(string: "\(ServerEnvironment.current.server.baseURI ?? "")/Users/\(publicUser.id ?? "")/Images/Primary?width=60&quality=80&tag=\(publicUser.primaryImageTag!)")!)
                                                    .frame(width: 60, height: 60)
                                                    .cornerRadius(30.0)
                                            } else {
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.8))
                                                    .font(.system(size: 35))
                                                    .frame(width: 60, height: 60)
                                                    .background(Color(red: 98 / 255, green: 121 / 255, blue: 205 / 255))
                                                    .cornerRadius(30.0)
                                                    .shadow(radius: 6)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Section {
                            Button {
                                viewModel.publicUsers.removeAll()
                                username = ""
                            } label: {
                                HStack {
                                    Text("Other User").font(.subheadline).fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "person.fill.questionmark")
                                        .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.8))
                                        .font(.system(size: 35))
                                        .frame(width: 60, height: 60)
                                        .background(Color(red: 98 / 255, green: 121 / 255, blue: 205 / 255))
                                        .cornerRadius(30.0)
                                        .shadow(radius: 6)
                                }
                            }
                        }
                    }
                } else {
                    Section(header: Text("Connect Manually")) {
                        TextField(NSLocalizedString("Server URL", comment: ""), text: $uri)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                        Button {
                            viewModel.connectToServer()
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
                    }

                    Section(header: Text("Discovered Servers")) {
                        if self.viewModel.searching {
                            ProgressView()
                        }
                        ForEach(self.viewModel.servers, id: \.id) { server in
                            Button(action: {
                                viewModel.connectToServer(at: server.url)
                            }, label: {
                                HStack {
                                    Text(server.name)
                                        .font(.headline)
                                    Text("• \(server.host)")
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
                }
            }
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
        .alert(item: $viewModel.errorMessage) { _ in
            Alert(title: Text("Error"), message: Text($viewModel.errorMessage.wrappedValue!), dismissButton: .default(Text("Try again")))
        }
        .navigationTitle(NSLocalizedString("Connect to Server", comment: ""))
    }
}
