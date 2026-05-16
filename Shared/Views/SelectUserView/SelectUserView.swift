//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import OrderedCollections
import SwiftUI

struct SelectUserView: View {

    typealias UserItem = (user: UserState, server: ServerState)

    @Default(.accentColor)
    private var accentColor
    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen
    @Default(.selectUserServerSelection)
    private var serverSelection
    @Default(.selectUserDisplayType)
    private var userListDisplayType
    @Default(.selectUserSortOrder)
    private var userSortOrder

    @Environment(\.localUserAuthenticationAction)
    private var authenticationAction
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Router
    private var router

    @State
    private var selectedUsers: Set<UserState> = []
    @State
    private var isEditing = false
    @State
    private var isPresentingConfirmDeleteUsers = false

    @StateObject
    private var viewModel = SelectUserViewModel()

    private var selectedServer: ServerState? {
        serverSelection.server(from: viewModel.servers.keys)
    }

    private var areAllUsersSelected: Bool {
        selectedUsers.count == userItems.count
    }

    private func toggleAllUsersSelected() {
        if areAllUsersSelected {
            selectedUsers.removeAll()
        } else {
            selectedUsers.insert(contentsOf: userItems.map(\.user))
        }
    }

    private var splashScreenImageSources: [ImageSource] {
        switch (serverSelection, selectUserAllServersSplashscreen) {
        case (.all, .all):
            viewModel
                .servers
                .keys
                .shuffled()
                .map(\.splashScreenImageSource)

        case let (.server(id), _), let (.all, .server(id)):
            viewModel
                .servers
                .keys
                .first(where: { $0.id == id })
                .map { [$0.splashScreenImageSource] } ?? []
        }
    }

    private var userItems: [UserItem] {
        let items: [UserItem] = {
            switch serverSelection {
            case .all:
                return viewModel.servers
                    .map { server, users in
                        users.map { UserItem(user: $0, server: server) }
                    }
                    .flattened()
            case let .server(id: id):
                guard let server = viewModel.servers.keys.first(where: { $0.id == id }) else {
                    return []
                }
                return viewModel.servers[server]!
                    .map { UserItem(user: $0, server: server) }
            }
        }()

        return {
            switch userSortOrder {
            case .name:
                items.sorted(using: \.user.username)
            case .lastSeen:
                items.sorted { lhs, rhs in
                    let lhsDate = lhs.user.data.lastActivityDate ?? .distantPast
                    let rhsDate = rhs.user.data.lastActivityDate ?? .distantPast
                    return lhsDate < rhsDate
                }
            }
        }()
    }

    private func addUser(server: ServerState) {
        UIDevice.impact(.light)
        router.route(to: .userSignIn(server: server))
    }

    private func delete(user: UserState) {
        selectedUsers.insert(user)
        isPresentingConfirmDeleteUsers = true
    }

    private func select(user: UserState) {
        selectedUsers.insert(user)

        Task { @MainActor in
            do {
                guard let authenticationAction else {
                    selectedUsers.remove(user)
                    return
                }

                let evaluatedPolicy = try await authenticationAction(
                    policy: user.accessPolicy,
                    reason: user.accessPolicy.authenticateReason(user: user)
                )
                let pin = (evaluatedPolicy as? PinEvaluatedUserAccessPolicy)?.pin ?? ""

                await viewModel.signIn(user, pin: pin)

                if user.accessPolicy == .requirePin {
                    selectedUsers.remove(user)
                }
            } catch is CancellationError {
                selectedUsers.remove(user)
            } catch {
                selectedUsers.remove(user)
                await viewModel.error(error)
            }
        }
    }

    private func onSignedIn(_ user: UserState) {
        Defaults[.lastSignedInUserID] = .signedIn(userID: user.id)
        Container.shared.currentUserSession.reset()
        UIDevice.feedback(.success)
        Notifications[.didSignIn].post()
    }

    @ViewBuilder
    private var splashScreenBackground: some View {
        if selectUserUseSplashscreen, splashScreenImageSources.isNotEmpty {
            ZStack(alignment: .top) {
                ImageView(splashScreenImageSources)
                    .pipeline(.Swiftfin.local)
                    .aspectRatio(contentMode: .fill)
                    .id(splashScreenImageSources)

                Color.black
                    .opacity(0.9)
            }
        }
    }

    var body: some View {
        ZStack {
            if viewModel.servers.isEmpty {
                ConnectToJellyfinView()
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        if userItems.isEmpty {
                            EmptyUserView {
                                if let selectedServer {
                                    addUser(server: selectedServer)
                                }
                            }
                            .contextMenu {
                                if selectedServer == nil {
                                    Text(L10n.selectServer)

                                    ForEach(viewModel.servers.keys) { server in
                                        Button {
                                            addUser(server: server)
                                        } label: {
                                            Text(server.name)
                                            Text(server.currentURL.absoluteString)
                                        }
                                    }
                                }
                            }
                        } else {
                            switch userListDisplayType {
                            case .list:
                                ListView(
                                    userItems: userItems,
                                    isEditing: $isEditing,
                                    selectedUsers: $selectedUsers,
                                    serverSelection: serverSelection,
                                    action: { select(user: $0) },
                                    onDelete: { delete(user: $0) }
                                )
                            case .grid:
                                GridView(
                                    userItems: userItems,
                                    isEditing: $isEditing,
                                    selectedUsers: $selectedUsers,
                                    serverSelection: serverSelection,
                                    action: { select(user: $0) },
                                    onDelete: { delete(user: $0) }
                                )
                            }
                        }
                    }
                    .animation(.linear(duration: 0.1), value: userListDisplayType)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focusSection()
                    .mask {
                        VStack(spacing: 0) {
                            #if os(tvOS)
                            if userListDisplayType == .list {
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white, location: 1),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 30)
                            }
                            #endif

                            Color.white

                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)
                        }
                        .ignoresSafeArea(.all, edges: .horizontal)
                    }

                    BottomBar(
                        servers: viewModel.servers.keys,
                        allUsers: userItems,
                        isEditing: $isEditing,
                        selectedUsers: $selectedUsers,
                        onDelete: {
                            isPresentingConfirmDeleteUsers = true
                        }
                    )
                    .focusSection()
                }
            }
        }
        .animation(.linear(duration: 0.1), value: selectedServer)
        .environment(\.isOverComplexContent, true)
        .isEditing(isEditing)
        .onFirstAppear {
            viewModel.getServers()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIDevice.isTV ? 100 : 30)
            }

            #if os(iOS)
            if horizontalSizeClass == .compact {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button(
                            areAllUsersSelected ? L10n.removeAll : L10n.selectAll,
                            action: toggleAllUsersSelected
                        )
                        .buttonStyle(.toolbarPill)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if isEditing {
                        Button(L10n.cancel) {
                            isEditing = false
                        }
                        .buttonStyle(.toolbarPill)
                    } else {
                        Menu {
                            AdvancedMenu(
                                hasUsers: userItems.isNotEmpty,
                                isEditing: $isEditing
                            )
                        } label: {
                            Label(L10n.advanced, systemImage: "gearshape.fill")
                        }
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if isEditing {
                        Button(L10n.delete) {
                            isPresentingConfirmDeleteUsers = true
                        }
                        .buttonStyle(.toolbarPill(.red))
                        .disabled(selectedUsers.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            #endif
        }
        .background {
            splashScreenBackground
                .ignoresSafeArea()
        }
        #if os(iOS)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        #endif
        .backport
        .onChange(of: isEditing) {
            guard !isEditing, !isPresentingConfirmDeleteUsers else { return }
            selectedUsers.removeAll()
        }
        .backport
        .onChange(of: viewModel.servers.keys) { _, newValue in
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
        .onReceive(viewModel.$error) { error in
            guard error != nil else { return }
            UIDevice.feedback(.error)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .signedIn(user):
                onSignedIn(user)
            }
        }
        .onNotification(.didConnectToServer) { server in
            viewModel.getServers()
            serverSelection = .server(id: server.id)
        }
        .onNotification(.didChangeCurrentServerURL) { _ in
            viewModel.getServers()
        }
        .onNotification(.didDeleteServer) { _ in
            viewModel.getServers()
        }
        .alert(
            L10n.delete,
            isPresented: $isPresentingConfirmDeleteUsers
        ) {
            Button(L10n.delete, role: .destructive) {
                viewModel.deleteUsers(selectedUsers)
                selectedUsers.removeAll()
                isEditing = false
                UIDevice.feedback(.success)
            }
        } message: {
            if selectedUsers.count == 1, let first = selectedUsers.first {
                Text(L10n.deleteUserSingleConfirmation(first.username))
            } else {
                Text(L10n.deleteUserMultipleConfirmation(selectedUsers.count))
            }
        }
        .errorMessage($viewModel.error)
    }
}
