//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import SwiftUI

struct UserListView: View {

    @EnvironmentObject
    private var userListRouter: UserListCoordinator.Router
    @ObservedObject
    var viewModel: UserListViewModel
    
    @State
    private var longPressedUser: SwiftfinStore.State.User?

    @ViewBuilder
    private var listView: some View {
        CollectionView(items: viewModel.users) { _, user, _ in
            UserProfileButton(user: user)
                .onSelect {
                    viewModel.signIn(user: user)
                }
                .onLongPressGesture {
                    longPressedUser = user
                }
        }
        .layout { _, layoutEnvironment in
                .grid(layoutEnvironment: layoutEnvironment,
                      layoutMode: .adaptive(withMinItemSize: 350),
                      itemSpacing: 20,
                      sectionInsets: .init(top: 20, leading: 20, bottom: 20, trailing: 20))
        }
        .padding(50)
    }

    @ViewBuilder
    private var noUserView: some View {
        VStack(spacing: 50) {
            L10n.signInGetStarted.text
                .frame(maxWidth: 500)
                .multilineTextAlignment(.center)
                .font(.body)
            
            Button {
                userListRouter.route(to: \.userSignIn, viewModel.server)
            } label: {
                L10n.signIn.text
                    .bold()
                    .font(.callout)
                    .frame(width: 400, height: 75)
                    .background(Color.jellyfinPurple)
            }
            .buttonStyle(.card)
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
            .alert(item: $longPressedUser) { user in
                Alert(title: Text(user.username),
                      primaryButton: .destructive(L10n.remove.text, action: { viewModel.remove(user: user) }),
                      secondaryButton: .cancel())
            }
            .onAppear {
                viewModel.fetchUsers()
            }
    }
}
