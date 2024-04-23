//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Factory
import JellyfinAPI
import SwiftUI

struct UserListView: View {

    @EnvironmentObject
    private var router: UserListCoordinator.Router

    @State
    private var longPressedUser: SwiftfinStore.State.User?

    @StateObject
    private var viewModel: UserListViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: UserListViewModel(server: server))
    }

    @ViewBuilder
    private var listView: some View {
        CollectionVGrid(
            viewModel.users,
            layout: .minWidth(
                250,
                insets: EdgeInsets.edgeInsets,
                itemSpacing: EdgeInsets.edgePadding,
                lineSpacing: EdgeInsets.edgePadding
            )
        ) { user in
            UserProfileButton(user: user)
                .onSelect {
                    viewModel.signIn(user: user)
                }
                .onLongPressGesture {
                    longPressedUser = user
                }
        }
    }

    @ViewBuilder
    private var noUserView: some View {
        VStack(spacing: 50) {
            L10n.signInGetStarted.text
                .frame(maxWidth: 500)
                .multilineTextAlignment(.center)
                .font(.body)

            Button {
                router.route(to: \.userSignIn, viewModel.server)
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

    var body: some View {
        ZStack {

            ImageView(viewModel.userSession.client.fullURL(with: Paths.getSplashscreen()))
                .ignoresSafeArea()

            Color.black
                .opacity(0.9)
                .ignoresSafeArea()

            if viewModel.users.isEmpty {
                noUserView
                    .offset(y: -50)
            } else {
                listView
            }
        }
        .navigationTitle(viewModel.server.name)
        .if(viewModel.users.isNotEmpty) { view in
            view.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.route(to: \.userSignIn, viewModel.server)
                    } label: {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                    }
                }
            }
        }
        .alert(item: $longPressedUser) { user in
            Alert(
                title: Text(user.username),
                primaryButton: .destructive(L10n.remove.text, action: { viewModel.remove(user: user) }),
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            viewModel.fetchUsers()
        }
    }
}
