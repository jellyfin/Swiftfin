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
    
    var body: some View {
        List {
            ForEach(viewModel.servers, id: \.id) { server in
                Text(server.name)
            }
        }
        .navigationTitle("Servers")
        .toolbar {
            
            ToolbarItemGroup(placement: .navigation) {
                HStack {
                    Button {
                        serverListRouter.route(to: \.connectToServer)
                    } label: {
                        Text("Connect")
                    }
                    
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
                }
            }
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button {
//                    serverListRouter.route(to: \.connectToServer)
//                } label: {
//                    Text("Connect")
//                }
//            }
        }
        .onAppear {
            viewModel.fetchServers()
        }
    }
}
