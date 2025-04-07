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
import LocalAuthentication
import SwiftUI

// TODO: authentication view during device authentication
//       - could use provided UI, but is iOS 16+
//       - could just ignore for iOS 15, or basic view
// TODO: user ordering
//       - name
//       - last signed in date
// TODO: between the server selection menu and delete toolbar,
//       figure out a way to make the grid/list and splash screen
//       not jump when size is changed
// TODO: fix splash screen pulsing
//       - should have used successful image source binding on ImageView?

struct SelectUserView: View {

    typealias UserItem = (user: UserState, server: ServerState)

    // MARK: - Defaults

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen
    @Default(.selectUserServerSelection)
    private var serverSelection
    @Default(.selectUserDisplayType)
    private var userListDisplayType

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @State
    private var isEditingUsers: Bool = false
    @State
    private var pin: String = ""
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
        UIDevice.impact(.light)
        router.route(to: \.userSignIn, server)
    }

    private func delete(user: UserState) {
        selectedUsers.insert(user)
        isPresentingConfirmDeleteUsers = true
    }

    // MARK: - Select User(s)

    private func select(user: UserState, needsPin: Bool = true) {
        Task { @MainActor in
            selectedUsers.insert(user)

            switch user.accessPolicy {
            case .requireDeviceAuthentication:
                try await performDeviceAuthentication(reason: L10n.userRequiresDeviceAuthentication(user.username))
            case .requirePin:
                if needsPin {
                    isPresentingLocalPin = true
                    return
                }
            case .none: ()
            }

            viewModel.send(.signIn(user, pin: pin))
        }
    }

    // MARK: - Perform Device Authentication

    // error logging/presentation is handled within here, just
    // use try+thrown error in local Task for early return
    private func performDeviceAuthentication(reason: String) async throws {
        let context = LAContext()
        var policyError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            viewModel.logger.critical("\(policyError!.localizedDescription)")

            await MainActor.run {
                self
                    .error =
                    JellyfinAPIError(L10n.unableToPerformDeviceAuthFaceID)
            }

            throw JellyfinAPIError(L10n.deviceAuthFailed)
        }

        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            viewModel.logger.critical("\(error.localizedDescription)")

            await MainActor.run {
                self.error = JellyfinAPIError(L10n.unableToPerformDeviceAuth)
            }

            throw JellyfinAPIError(L10n.deviceAuthFailed)
        }
    }

    // MARK: - Advanced Menu

    @ViewBuilder
    private var advancedMenu: some View {
        Menu(L10n.advanced, systemImage: "gearshape.fill") {

            Section {

                if userItems.isNotEmpty {
                    ConditionalMenu(
                        tracking: selectedServer,
                        action: addUserSelected
                    ) {
                        Section(L10n.servers) {
                            let servers = viewModel.servers.keys

                            ForEach(servers) { server in
                                Button {
                                    addUserSelected(server: server)
                                } label: {
                                    Text(server.name)
                                    Text(server.currentURL.absoluteString)
                                }
                            }
                        }
                    } label: {
                        Label(L10n.addUser, systemImage: "plus")
                    }

                    Toggle(
                        L10n.editUsers,
                        systemImage: "person.crop.circle",
                        isOn: $isEditingUsers
                    )
                }
            }

            if viewModel.servers.isNotEmpty {
                Picker(selection: $userListDisplayType) {
                    ForEach(LibraryDisplayType.allCases, id: \.hashValue) {
                        Label($0.displayTitle, systemImage: $0.systemImage)
                            .tag($0)
                    }
                } label: {
                    Text(L10n.layout)
                    Text(userListDisplayType.displayTitle)
                    Image(systemName: userListDisplayType.systemImage)
                }
                .pickerStyle(.menu)
            }

            Section {
                Button(L10n.advanced, systemImage: "gearshape.fill") {
                    router.route(to: \.advancedSettings)
                }
            }
        }
    }

    @ViewBuilder
    private var addUserGridButtonView: some View {
        AddUserGridButton(
            selectedServer: selectedServer,
            servers: viewModel.servers.keys,
            action: addUserSelected
        )
    }

    @ViewBuilder
    private func userGridItemView(for item: UserItem) -> some View {
        let user = item.user
        let server = item.server

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
            delete(user: user)
        }
        .environment(\.isSelected, selectedUsers.contains(user))
    }

    // MARK: - iPad Grid Content View

    @ViewBuilder
    private var padGridContentView: some View {
        if userItems.isEmpty {
            CenteredLazyVGrid(
                data: [0],
                id: \.self,
                minimum: 150,
                maximum: 300,
                spacing: EdgeInsets.edgePadding
            ) { _ in
                addUserGridButtonView
            }
        } else {
            CenteredLazyVGrid(
                data: userItems,
                id: \.user.id,
                minimum: 150,
                maximum: 300,
                spacing: EdgeInsets.edgePadding,
                content: userGridItemView
            )
        }
    }

    // MARK: - iPhone Grid Content View

    @ViewBuilder
    private var phoneGridContentView: some View {
        if userItems.isEmpty {
            CenteredLazyVGrid(
                data: [0],
                id: \.self,
                columns: 2
            ) { _ in
                addUserGridButtonView
            }
        } else {
            CenteredLazyVGrid(
                data: userItems,
                id: \.user.id,
                columns: 2,
                spacing: EdgeInsets.edgePadding,
                content: userGridItemView
            )
            .edgePadding()
        }
    }

    // MARK: - List Content View

    @ViewBuilder
    private var listContentView: some View {
        List {
            let userItems = self.userItems

            if userItems.isEmpty {
                AddUserListRow(
                    selectedServer: selectedServer,
                    servers: viewModel.servers.keys,
                    action: addUserSelected
                )
                .listRowBackground(EmptyView())
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            }

            ForEach(userItems, id: \.user.id) { item in
                let user = item.user
                let server = item.server

                UserListRow(
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
                    delete(user: user)
                }
                .environment(\.isSelected, selectedUsers.contains(user))
                .swipeActions {
                    if !isEditingUsers {
                        Button(
                            L10n.delete,
                            systemImage: "trash"
                        ) {
                            delete(user: user)
                        }
                        .tint(.red)
                    }
                }
            }
            .listRowBackground(EmptyView())
            .listRowInsets(.zero)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    // MARK: - User View

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            ZStack {
                switch userListDisplayType {
                case .grid:
                    Group {
                        if UIDevice.isPhone {
                            phoneGridContentView
                        } else {
                            padGridContentView
                        }
                    }
                    .scrollIfLargerThanContainer(padding: 100)
                case .list:
                    listContentView
                }
            }
            .animation(.linear(duration: 0.1), value: userListDisplayType)
            .environment(\.isEditing, isEditingUsers)
            .frame(maxHeight: .infinity)
            .mask {
                VStack(spacing: 0) {
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
            }

            if !isEditingUsers {
                ServerSelectionMenu(
                    selection: $serverSelection,
                    selectedServer: selectedServer,
                    servers: viewModel.servers.keys
                )
                .edgePadding([.bottom, .horizontal])
            }
        }
        .background {
            if selectUserUseSplashscreen, splashScreenImageSources.isNotEmpty {
                ZStack {
                    Color.clear

                    ImageView(splashScreenImageSources)
                        .pipeline(.Swiftfin.local)
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity.animation(.linear(duration: 0.1)))
                        .id(splashScreenImageSources)

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
        VStack(spacing: 10) {
            L10n.connectToJellyfinServerStart.text
                .frame(minWidth: 50, maxWidth: 240)
                .multilineTextAlignment(.center)

            PrimaryButton(title: L10n.connect)
                .onSelect {
                    router.route(to: \.connectToServer)
                }
                .frame(maxWidth: 300)
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(L10n.users)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(uiImage: .jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30)
            }

            ToolbarItem(placement: .topBarLeading) {
                if isEditingUsers {
                    if selectedUsers.count == userItems.count {
                        Button(L10n.removeAll) {
                            selectedUsers.removeAll()
                        }
                        .buttonStyle(.toolbarPill)
                    } else {
                        Button(L10n.selectAll) {
                            selectedUsers.insert(contentsOf: userItems.map(\.user))
                        }
                        .buttonStyle(.toolbarPill)
                    }
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if isEditingUsers {
                    Button(isEditingUsers ? L10n.cancel : L10n.edit) {
                        isEditingUsers.toggle()

                        UIDevice.impact(.light)

                        if !isEditingUsers {
                            selectedUsers.removeAll()
                        }
                    }
                    .buttonStyle(.toolbarPill)
                } else {
                    advancedMenu
                }
            }

            ToolbarItem(placement: .bottomBar) {
                if isEditingUsers {
                    Button(L10n.delete) {
                        isPresentingConfirmDeleteUsers = true
                    }
                    .buttonStyle(.toolbarPill(.red))
                    .disabled(selectedUsers.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .onAppear {
            viewModel.send(.getServers)
        }
        .onChange(of: isEditingUsers) { newValue in
            guard !newValue else { return }
            selectedUsers.removeAll()
        }
        .onChange(of: isPresentingConfirmDeleteUsers) { newValue in
            guard !newValue else { return }
            isEditingUsers = false
            selectedUsers.removeAll()
        }
        .onChange(of: isPresentingLocalPin) { newValue in
            guard newValue else { return }
            pin = ""
        }
        .onChange(of: viewModel.servers.keys) { newValue in
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
                UIDevice.feedback(.error)
                self.error = eventError
            case let .signedIn(user):
                UIDevice.feedback(.success)

                Defaults[.lastSignedInUserID] = .signedIn(userID: user.id)
                Container.shared.currentUserSession.reset()
                Notifications[.didSignIn].post()
            }
        }
        .onNotification(.didConnectToServer) { server in
            viewModel.send(.getServers)
            serverSelection = .server(id: server.id)
        }
        .onNotification(.didChangeCurrentServerURL) { _ in
            viewModel.send(.getServers)
        }
        .onNotification(.didDeleteServer) { _ in
            viewModel.send(.getServers)
        }
        .alert(
            L10n.deleteUser,
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

            TextField(L10n.pin, text: $pin)
                .keyboardType(.numberPad)

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure (for length)
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
