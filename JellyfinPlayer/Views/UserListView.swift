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
            VStack {
                ForEach(viewModel.users, id: \.id) { user in
                    Button {
                        viewModel.login(user: user)
                    } label: {
                        ZStack(alignment: Alignment.leading) {
                            Rectangle()
                                .foregroundColor(Color(UIColor.secondarySystemFill))
                                .frame(height: 70)
                                .cornerRadius(10)
                            
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 46))
                                    .foregroundColor(.primary)
                                
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
                }
            }
        }
    }
    
    @ViewBuilder
    private var noUserView: some View {
        VStack {
            Text("Login to a user to get started.")
                .frame(minWidth: 50, maxWidth: 240)
                .multilineTextAlignment(.center)
            
            Button {
                userListRouter.route(to: \.userSignIn, viewModel.server)
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(Color.jellyfinPurple)
                        .frame(maxWidth: 500, maxHeight: 50)
                        .frame(height: 50)
                        .cornerRadius(10)
                        .padding([.leading, .trailing], 30)
                        .padding([.top, .bottom], 20)
                    
                    Text("Login")
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
