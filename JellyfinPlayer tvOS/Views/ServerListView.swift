//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import CoreStore
import SwiftUI

struct ServerListView: View {
    
    @EnvironmentObject var serverListRouter: ServerListCoordinator.Router
    @ObservedObject var viewModel: ServerListViewModel
    
    @ViewBuilder
    private var listView: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.servers, id: \.id) { server in
                    Button {
                        serverListRouter.route(to: \.userList, server)
                    } label: {
                        HStack {
                            Image(systemName: "server.rack")
                                .font(.system(size: 72))
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(server.name)
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                
                                Text(server.uri)
                                    .font(.footnote)
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                                
                                Text(viewModel.userTextFor(server: server))
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.remove(server: server)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(.top, 100)
    }
    
    @ViewBuilder
    private var noServerView: some View {
        VStack {
            Text("Connect to a Jellyfin server to get started")
                .frame(minWidth: 50, maxWidth: 500)
                .multilineTextAlignment(.center)
                .font(.callout)
            
            Button {
                serverListRouter.route(to: \.connectToServer)
            } label: {
                Text("Connect")
                    .bold()
                    .font(.callout)
            }
            .padding(.top, 40)
        }
    }
    
    @ViewBuilder
    private var innerBody: some View {
        if viewModel.servers.isEmpty {
            noServerView
                .offset(y: -50)
        } else {
            listView
                .frame(width: 3000)
        }
    }
    
    @ViewBuilder
    private var toolbarContent: some View {
        if viewModel.servers.isEmpty {
            EmptyView()
        } else {
            HStack {
                Button {
                    SwiftfinStore.dataStack.perform(asynchronous: { transaction in
                        try! transaction.deleteAll(From<SwiftfinStore.Models.StoredServer>())
                        try! transaction.deleteAll(From<SwiftfinStore.Models.StoredUser>())
                        try! transaction.deleteAll(From<SwiftfinStore.Models.StoredAccessToken>())
                    }) { _ in
                        SwiftfinStore.Defaults.suite[.lastServerUserID] = nil
                        viewModel.fetchServers()
                    }
                } label: {
                    Text("Purge")
                }
                
                Button {
                    serverListRouter.route(to: \.connectToServer)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }
    
    var body: some View {
        innerBody
            .frame(width: 1500)
        .navigationTitle("Servers")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarContent
            }
        }
        .onAppear {
            viewModel.fetchServers()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ServerListView(viewModel: ServerListViewModel())
        }
    }
}
