//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

struct UserListView: View {
    
    @EnvironmentObject var userListRouter: UserListCoordinator.Router
    @ObservedObject var viewModel: UserListViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.users, id: \.id) { user in
                Button {
                    viewModel.login(user: user)
                } label: {
                    HStack {
                        Text(user.username)
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                }
            }
        }
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack {
                    Button {
                        userListRouter.route(to: \.userLogin, viewModel.server)
                    } label: {
                        Text("Connect")
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchUsers()
        }
    }
}
