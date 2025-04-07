//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import OrderedCollections
import SwiftUI

struct SelectUserView: View {

    typealias UserItem = (user: UserState, server: ServerState)

    // MARK: - Defaults

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen
    @Default(.selectUserServerSelection)
    private var serverSelection

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    // MARK: - Select User Variables

    @State
    private var isEditingUsers: Bool = false
    @State
    private var pin: String = ""
    @State
    private var scrollViewOffset: CGFloat = 0
    @State
    private var selectedUsers: Set<UserState> = []

    // MARK: - Dialog States

    @State
    private var isPresentingConfirmDeleteUsers = false
    @State
    private var isPresentingLocalPin: Bool = false

    // MARK: - Error State

    @State
    private var error: Error? = nil

    @StateObject
    private var viewModel = SelectUserViewModel()

    private var selectedServer: ServerState? {
        serverSelection.server(from: viewModel.servers.keys)
    }

    private var splashScreenImageSources: [ImageSource] {
        switch (serverSelection, selectUserAllServersSplashscreen) {
        case (.all, .all):
            return viewModel
                .servers
                .keys
                .shuffled()
                .map(\.splashScreenImageSource)

        // need to evaluate server with id selection first
        case let (.server(id), _), let (.all, .server(id)):
            guard let server = viewModel
                .servers
                .keys
                .first(where: { $0.id == id }) else { return [] }

            return [server.splashScreenImageSource]
        }
    }

    private var userItems: [UserItem] {
        switch serverSelection {
        case .all:
            return viewModel.servers
                .map { server, users in
                    users.map { (server: server, user: $0) }
                }
                .flatMap { $0 }
                .sorted(using: \.user.username)
                .reversed()
                .map { UserItem(user: $0.user, server: $0.server) }
        case let .server(id: id):
            guard let server = viewModel.servers.keys.first(where: { server in server.id == id }) else {
                return []
            }

            return viewModel.servers[server]!
                .sorted(using: \.username)
                .map { UserItem(user: $0, server: server) }
        }
    }

    private func addUserSelected(server: ServerState) {
        router.route(to: \.userSignIn, server)
    }

    private func delete(user: UserState) {
        selectedUsers.insert(user)
        isPresentingConfirmDeleteUsers = true
    }

    // MARK: - Select User(s)

    private func select(user: UserState, needsPin: Bool = true) {
        selectedUsers.insert(user)

        switch user.accessPolicy {
        case .requireDeviceAuthentication:
            // Do nothing, no device authentication on tvOS
            break
        case .requirePin:
            if needsPin {
                isPresentingLocalPin = true
                return
            }
        case .none: ()
        }

        viewModel.send(.signIn(user, pin: pin))
    }

    // MARK: - Grid Content View

    @ViewBuilder
    private var userGrid: some View {
        CenteredLazyVGrid(
            data: userItems,
            id: \.user.id,
            columns: 5,
            spacing: EdgeInsets.edgePadding
        ) { gridItem in
            let user = gridItem.user
            let server = gridItem.server

            UserGridButton(
                user: user,
                server: server,
                showServer: serverSelection == .all
            ) {
                if isEditingUsers {
                    selectedUsers.toggle(value: user)
                } else {
                    select(user: user)
                }
            } onDelete: {
                selectedUsers.insert(user)
                isPresentingConfirmDeleteUsers = true
            }
            .environment(\.isSelected, selectedUsers.contains(user))
        }
    }

    @ViewBuilder
    private var addUserButtonGrid: some View {
        CenteredLazyVGrid(
            data: [0],
            id: \.self,
            columns: 5
        ) { _ in
            AddUserGridButton(
                selectedServer: selectedServer,
                servers: viewModel.servers.keys
            ) { server in
                router.route(to: \.userSignIn, server)
            }
        }
    }

    // MARK: - User View

    @ViewBuilder
    private var contentView: some View {
        VStack {
            ZStack {
                Color.clear

                VStack(spacing: 0) {

                    Color.clear
                        .frame(height: 100)

                    Group {
                        if userItems.isEmpty {
                            addUserButtonGrid
                        } else {
                            userGrid
                        }
                    }
                    .focusSection()
                }
                .scrollIfLargerThanContainer(padding: 100)
                .scrollViewOffset($scrollViewOffset)
            }
            .environment(\.isEditing, isEditingUsers)

            SelectUserBottomBar(
                isEditing: $isEditingUsers,
                serverSelection: $serverSelection,
                selectedServer: selectedServer,
                servers: viewModel.servers.keys,
                areUsersSelected: selectedUsers.isNotEmpty,
                hasUsers: userItems.isNotEmpty
            ) {
                isPresentingConfirmDeleteUsers = true
            } toggleAllUsersSelected: {
                if selectedUsers.isNotEmpty {
                    selectedUsers.removeAll()
                } else {
                    selectedUsers.insert(contentsOf: userItems.map(\.user))
                }
            }
            .focusSection()
        }
        .animation(.linear(duration: 0.1), value: scrollViewOffset)
        .background {
            if selectUserUseSplashscreen, splashScreenImageSources.isNotEmpty {
                ZStack {
                    ImageView(splashScreenImageSources)
                        .pipeline(.Swiftfin.local)
                        .aspectRatio(contentMode: .fill)
                        .id(splashScreenImageSources)
                        .transition(.opacity)
                        .animation(.linear, value: splashScreenImageSources)

                    Color.black
                        .opacity(0.9)
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Connect to Server View

    @ViewBuilder
    private var connectToServerView: some View {
        VStack(spacing: 50) {
            L10n.connectToJellyfinServerStart.text
                .font(.body)
                .frame(minWidth: 50, maxWidth: 500)
                .multilineTextAlignment(.center)

            Button {
                router.route(to: \.connectToServer)
            } label: {
                L10n.connect.text
                    .font(.callout)
                    .fontWeight(.bold)
                    .frame(width: 400, height: 75)
                    .background(Color.jellyfinPurple)
            }
            .buttonStyle(.card)
        }
    }

    // MARK: - Functions

    private func didDelete(_ server: ServerState) {
        viewModel.send(.getServers)

        if case let SelectUserServerSelection.server(id: id) = serverSelection, server.id == id {
            if viewModel.servers.keys.count == 1, let first = viewModel.servers.keys.first {
                serverSelection = .server(id: first.id)
            } else {
                serverSelection = .all
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.servers.isEmpty {
                connectToServerView
            } else {
                contentView
            }
        }
        .ignoresSafeArea()
        .navigationBarBranding()
        .onAppear {
            viewModel.send(.getServers)
        }
        .onChange(of: isEditingUsers) {
            guard !isEditingUsers else { return }
            selectedUsers.removeAll()
        }
        .onChange(of: isPresentingLocalPin) {
            if isPresentingLocalPin {
                pin = ""
            } else {
                selectedUsers.removeAll()
            }
        }
        .onChange(of: viewModel.servers.keys) {
            let newValue = viewModel.servers.keys

            if case let SelectUserServerSelection.server(id: id) = serverSelection,
               !newValue.contains(where: { $0.id == id })
            {
                if newValue.count == 1, let firstServer = newValue.first {
                    let newSelection = SelectUserServerSelection.server(id: firstServer.id)
                    serverSelection = newSelection
                    selectUserAllServersSplashscreen = newSelection
                } else {
                    serverSelection = .all
                    selectUserAllServersSplashscreen = .all
                }
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                self.error = eventError
            case let .signedIn(user):
                Defaults[.lastSignedInUserID] = .signedIn(userID: user.id)
                Container.shared.currentUserSession.reset()
                Notifications[.didSignIn].post()
            }
        }
        .onNotification(.didConnectToServer) { server in
            viewModel.send(.getServers)
            serverSelection = .server(id: server.id)
        }
        .onNotification(.didChangeCurrentServerURL) { server in
            viewModel.send(.getServers)
            serverSelection = .server(id: server.id)
        }
        .onNotification(.didDeleteServer) { server in
            didDelete(server)
        }
        .confirmationDialog(
            Text(L10n.deleteUser),
            isPresented: $isPresentingConfirmDeleteUsers
        ) {
            Button(L10n.delete, role: .destructive) {
                viewModel.send(.deleteUsers(selectedUsers))
            }
        } message: {
            if selectedUsers.count == 1, let first = selectedUsers.first {
                Text(L10n.deleteUserSingleConfirmation(first.username))
            } else {
                Text(L10n.deleteUserMultipleConfirmation(selectedUsers.count))
            }
        }
        .alert(L10n.signIn, isPresented: $isPresentingLocalPin) {

            // TODO: Verify on tvOS 18
            // https://forums.developer.apple.com/forums/thread/739545
            // TextField(L10n.pin, text: $pin)
            TextField(text: $pin) {}
                .keyboardType(.numberPad)

            Button(L10n.signIn) {
                guard let user = selectedUsers.first else {
                    assertionFailure("User not selected")
                    return
                }
                select(user: user, needsPin: false)
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: {
            if let user = selectedUsers.first, user.pinHint.isNotEmpty {
                Text(user.pinHint)
            } else {
                let username = selectedUsers.first?.username ?? .emptyDash

                Text(L10n.enterPinForUser(username))
            }
        }
        .errorMessage($error)
    }
}
