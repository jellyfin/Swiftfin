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

    private var listView: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.users, id: \.id) { user in
                    Button {
                        viewModel.login(user: user)
                    } label: {
                        ZStack(alignment: Alignment.leading) {
                            Rectangle()
                                .foregroundColor(Color(UIColor.secondarySystemFill))
                                .frame(height: 50)
                                .cornerRadius(10)

                            HStack {
                                Text(user.username)
                                    .font(.title2)

                                Spacer()

                                if viewModel.isLoading {
                                    ProgressView()
                                }
                            }.padding(.leading)
                        }
                        .padding()
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.remove(user: user)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var noUserView: some View {
        VStack {
            Text("Sign in to get started")
                .frame(minWidth: 50, maxWidth: 240)
                .multilineTextAlignment(.center)

            Button {
                userListRouter.route(to: \.userSignIn, viewModel.server)
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(Color.jellyfinPurple)
                        .frame(maxWidth: 400, maxHeight: 50)
                        .frame(height: 50)
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                        .padding([.top, .bottom], 20)

                    Text("Sign in")
                        .foregroundColor(Color.white)
                        .bold()
                }
            }
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
        HStack {
            Button {
                userListRouter.route(to: \.serverDetail, viewModel.server)
            } label: {
                Image(systemName: "info.circle.fill")
            }
            
            if !viewModel.users.isEmpty {
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
