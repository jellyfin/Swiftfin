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
    
    @ViewBuilder
    private var listView: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.users, id: \.id) { user in
                    Button {
                        viewModel.login(user: user)
                    } label: {
                        HStack {
                            Text(user.username)
                                .font(.title2)
                            
                            Spacer()
                            
                            if viewModel.isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .padding(.horizontal, 100)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.remove(user: user)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.top, 50)
        }
        .padding(.top, 50)
    }
    
    @ViewBuilder
    private var noUserView: some View {
        VStack {
            Text("Sign in to get started")
                .frame(minWidth: 50, maxWidth: 500)
                .multilineTextAlignment(.center)
                .font(.callout)
            
            Button {
                userListRouter.route(to: \.userSignIn, viewModel.server)
            } label: {
                Text("Sign in")
                    .bold()
                    .font(.callout)
            }
            .padding(.top, 40)
        }
    }
    
    @ViewBuilder
    private var innerBody: some View {
        if viewModel.users.isEmpty {
            noUserView
                .offset(y: -50)
        } else {
            listView
        }
    }
    
    @ViewBuilder
    private var toolbarContent: some View {
        if viewModel.users.isEmpty {
            EmptyView()
        } else {
            HStack {
                Button {
                    userListRouter.route(to: \.userSignIn, viewModel.server)
                } label: {
                    Image(systemName: "person.crop.circle.fill.badge.plus")
                }
            }
        }
    }
    
    var body: some View {
        innerBody
        .navigationTitle(viewModel.server.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarContent
            }
        }
        .onAppear {
            viewModel.fetchUsers()
        }
    }
}
