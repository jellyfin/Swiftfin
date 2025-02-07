//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI
import OrderedCollections
import SwiftUI

// TODO: user deletion

struct SelectUserView: View {

    // MARK: - User Grid Item Enum

    private enum UserGridItem: Hashable {
        case user(UserState, server: ServerState)
        case addUser
    }

    // MARK: - Defaults

    @Default(.selectUserServerSelection)
    private var serverSelection
    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen

    // MARK: - Environment Variable

    @Environment(\.colorScheme)
    private var colorScheme

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @StateObject
    private var viewModel = SelectUserViewModel()

    // MARK: - Select User Variables

    @State
    private var contentSize: CGSize = .zero
    @State
    private var gridItems: OrderedSet<UserGridItem> = []
    @State
    private var gridItemSize: CGSize = .zero
    @State
    private var isEditingUsers: Bool = false
    @State
    private var padGridItemColumnCount: Int = 1
    @State
    private var pin: String = ""
    @State
    private var scrollViewOffset: CGFloat = 0
    @State
    private var selectedUsers: Set<UserState> = []
    @State
    private var splashScreenImageSource: ImageSource? = nil

    private var users: [UserState] {
        gridItems.compactMap { item in
            switch item {
            case let .user(user, _):
                return user
            default:
                return nil
            }
        }
    }

    // MARK: - Dialog States

    @State
    private var isPresentingConfirmDeleteUsers = false
    @State
    private var isPresentingServers: Bool = false
    @State
    private var isPresentingLocalPin: Bool = false

    // MARK: - Error State

    @State
    private var error: Error? = nil

    // MARK: - Selected Server

    private var selectedServer: ServerState? {
        if case let SelectUserServerSelection.server(id: id) = serverSelection,
           let server = viewModel.servers.keys.first(where: { server in server.id == id })
        {
            return server
        }

        return nil
    }

    // MARK: - Make Grid Items

    private func makeGridItems(for serverSelection: SelectUserServerSelection) -> OrderedSet<UserGridItem> {
        switch serverSelection {
        case .all:
            let items = viewModel.servers
                .map { server, users in
                    users.map { (server: server, user: $0) }
                }
                .flatMap { $0 }
                .sorted(using: \.user.username)
                .reversed()
                .map { UserGridItem.user($0.user, server: $0.server) }
                .appending(.addUser)

            return OrderedSet(items)
        case let .server(id: id):
            guard let server = viewModel.servers.keys.first(where: { server in server.id == id }) else {
                assertionFailure("server with ID not found?")
                return [.addUser]
            }

            let items = viewModel.servers[server]!
                .sorted(using: \.username)
                .map { UserGridItem.user($0, server: server) }
                .appending(.addUser)

            return OrderedSet(items)
        }
    }

    // MARK: - Make Splash Screen Image Source

    // For all server selection, .all is random
    private func makeSplashScreenImageSource(
        serverSelection: SelectUserServerSelection,
        allServersSelection: SelectUserServerSelection
    ) -> ImageSource? {
        switch (serverSelection, allServersSelection) {
        case (.all, .all):
            return viewModel
                .servers
                .keys
                .randomElement()?
                .splashScreenImageSource()

        // need to evaluate server with id selection first
        case let (.server(id), _), let (.all, .server(id)):
            return viewModel
                .servers
                .keys
                .first { $0.id == id }?
                .splashScreenImageSource()
        }
    }

    // MARK: - Grid Item Offset

    private func gridItemOffset(index: Int) -> CGFloat {
        let lastRowIndices = (gridItems.count - gridItems.count % padGridItemColumnCount ..< gridItems.count)

        guard lastRowIndices.contains(index) else { return 0 }

        let lastRowMissing = padGridItemColumnCount - gridItems.count % padGridItemColumnCount
        return CGFloat(lastRowMissing) * (gridItemSize.width + EdgeInsets.edgePadding) / 2
    }

    // MARK: - Select User(s)

    private func select(user: UserState, needsPin: Bool = true) {
        Task { @MainActor in
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
    }

    // MARK: - Grid Content View

    @ViewBuilder
    private var gridContentView: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: EdgeInsets.edgePadding), count: 5)

        LazyVGrid(columns: columns, spacing: EdgeInsets.edgePadding) {
            ForEach(Array(gridItems.enumerated().map(\.offset)), id: \.hashValue) { index in
                let item = gridItems[index]

                gridItemView(for: item)
                    .trackingSize($gridItemSize)
                    .offset(x: gridItemOffset(index: index))
            }
        }
        .padding(EdgeInsets.edgePadding * 2.5)
        .onChange(of: gridItemSize) { _, newValue in
            let columns = Int(contentSize.width / (newValue.width + EdgeInsets.edgePadding))

            padGridItemColumnCount = columns
        }
    }

    // MARK: - Grid Content View

    @ViewBuilder
    private func gridItemView(for item: UserGridItem) -> some View {
        switch item {
        case let .user(user, server):
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
            .environment(\.isEditing, isEditingUsers)
            .environment(\.isSelected, selectedUsers.contains(user))
        case .addUser:
            AddUserButton(
                serverSelection: $serverSelection,
                servers: viewModel.servers.keys
            ) { server in
                router.route(to: \.userSignIn, server)
            }
            .environment(\.isEnabled, !isEditingUsers)
        }
    }

    // MARK: - User View

    @ViewBuilder
    private var userView: some View {
        VStack {
            ZStack {
                Color.clear
                    .trackingSize($contentSize)

                VStack(spacing: 0) {

                    Color.clear
                        .frame(height: 100)

                    gridContentView
                        .focusSection()
                }
                .scrollIfLargerThanContainer(padding: 100)
                .scrollViewOffset($scrollViewOffset)
            }

            SelectUserBottomBar(
                isEditing: $isEditingUsers,
                serverSelection: $serverSelection,
                areUsersSelected: selectedUsers.isNotEmpty,
                viewModel: viewModel,
                userCount: gridItems.count,
                onDelete: {
                    isPresentingConfirmDeleteUsers = true
                }
            ) {
                if selectedUsers.count == users.count {
                    selectedUsers.removeAll()
                } else {
                    selectedUsers.insert(contentsOf: users)
                }
            }
            .focusSection()
        }
        .animation(.linear(duration: 0.1), value: scrollViewOffset)
        .background {
            if let splashScreenImageSource, selectUserUseSplashscreen {
                ZStack {
                    ImageView(splashScreenImageSource)
                        .aspectRatio(contentMode: .fill)
                        .id(splashScreenImageSource)
                        .transition(.opacity)
                        .animation(.linear, value: splashScreenImageSource)

                    Color.black
                        .opacity(0.9)
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Empty View

    @ViewBuilder
    private var emptyView: some View {
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

        setSplashScreenImageSource()
    }

    // MARK: - Did Appear

    private func didAppear() {
        viewModel.send(.getServers)

        setSplashScreenImageSource()
    }

    // MARK: - Set Splash Screen Image Source

    private func setSplashScreenImageSource() {
        splashScreenImageSource = makeSplashScreenImageSource(
            serverSelection: serverSelection,
            allServersSelection: .all
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.servers.isEmpty {
                emptyView
            } else {
                userView
            }
        }
        .ignoresSafeArea()
        .navigationBarBranding()
        .onAppear {
            didAppear()
        }
        .onChange(of: isEditingUsers) { _, newValue in
            guard !newValue else { return }
            selectedUsers.removeAll()
        }
        .onChange(of: serverSelection) { _, newValue in
            gridItems = makeGridItems(for: newValue)

            setSplashScreenImageSource()
        }
        .onChange(of: isPresentingLocalPin) { _, newValue in
            if newValue {
                pin = ""
            } else {
                selectedUsers.removeAll()
            }
        }
        .onChange(of: viewModel.servers) { _, _ in
            gridItems = makeGridItems(for: serverSelection)

            splashScreenImageSource = makeSplashScreenImageSource(
                serverSelection: serverSelection,
                allServersSelection: .all
            )
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
            isPresented: $isPresentingConfirmDeleteUsers,
            presenting: selectedUsers
        ) { selectedUsers in
            Button(L10n.delete, role: .destructive) {
                viewModel.send(.deleteUsers(Array(selectedUsers)))
                isEditingUsers = false
            }
        } message: { selectedUsers in
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
