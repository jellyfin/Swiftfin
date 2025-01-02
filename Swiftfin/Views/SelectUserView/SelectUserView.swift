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
import LocalAuthentication
import OrderedCollections
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

struct SelectUserView: View {

    // MARK: - Defaults

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen
    @Default(.selectUserServerSelection)
    private var serverSelection
    @Default(.selectUserDisplayType)
    private var userListDisplayType

    // MARK: - Environment Variable

    @Environment(\.colorScheme)
    private var colorScheme

    // MARK: - Focus Fields

    private enum UserGridItem: Hashable {
        case user(UserState, server: ServerState)
        case addUser
    }

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @StateObject
    private var viewModel = SelectUserViewModel()

    // MARK: - Select Users Variables

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
    private var selectedUsers: Set<UserState> = []
    @State
    private var splashScreenImageSources: [ImageSource] = []

    // MARK: - Dialog States

    @State
    private var isPresentingConfirmDeleteUsers = false
    @State
    private var isPresentingLocalPin: Bool = false

    // MARK: - Error State

    @State
    private var error: Error? = nil

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

    // MARK: - Select Server

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
    private func makeSplashScreenImageSources(
        serverSelection: SelectUserServerSelection,
        allServersSelection: SelectUserServerSelection
    ) -> [ImageSource] {
        switch (serverSelection, allServersSelection) {
        case (.all, .all):
            return viewModel
                .servers
                .keys
                .shuffled()
                .map { $0.splashScreenImageSource() }

        // need to evaluate server with id selection first
        case let (.server(id), _), let (.all, .server(id)):
            return [
                viewModel
                    .servers
                    .keys
                    .first { $0.id == id }?
                    .splashScreenImageSource() ?? .init(),
            ]
        }
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
                if gridItems.count > 1 {
                    Button(L10n.editUsers, systemImage: "person.crop.circle") {
                        isEditingUsers.toggle()
                    }
                }
            }

            if !viewModel.servers.isEmpty {
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

    // MARK: - iPad Grid Item Offset

    private func padGridItemOffset(index: Int) -> CGFloat {
        let lastRowIndices = (gridItems.count - gridItems.count % padGridItemColumnCount ..< gridItems.count)

        guard lastRowIndices.contains(index) else { return 0 }

        let lastRowMissing = padGridItemColumnCount - gridItems.count % padGridItemColumnCount
        return CGFloat(lastRowMissing) * (gridItemSize.width + EdgeInsets.edgePadding) / 2
    }

    // MARK: - iPad Grid Content View

    @ViewBuilder
    private var padGridContentView: some View {
        let columns = [GridItem(.adaptive(minimum: 150, maximum: 300), spacing: EdgeInsets.edgePadding)]

        LazyVGrid(columns: columns, spacing: EdgeInsets.edgePadding) {
            ForEach(Array(gridItems.enumerated().map(\.offset)), id: \.hashValue) { index in
                let item = gridItems[index]

                gridItemView(for: item)
                    .trackingSize($gridItemSize)
                    .offset(x: padGridItemOffset(index: index))
            }
        }
        .edgePadding()
        .scrollIfLargerThanContainer(padding: 100)
        .onChange(of: gridItemSize) { newValue in
            let columns = Int(contentSize.width / (newValue.width + EdgeInsets.edgePadding))

            padGridItemColumnCount = columns
        }
    }

    // MARK: - iPhone Grid Content View

    @ViewBuilder
    private var phoneGridContentView: some View {
        let columns = [GridItem(.flexible(), spacing: EdgeInsets.edgePadding), GridItem(.flexible())]

        LazyVGrid(columns: columns, spacing: EdgeInsets.edgePadding) {
            ForEach(gridItems, id: \.hashValue) { item in
                gridItemView(for: item)
                    .if(gridItems.count % 2 == 1 && item == gridItems.last) { view in
                        view.trackingSize($gridItemSize)
                            .offset(x: (gridItemSize.width + EdgeInsets.edgePadding) / 2)
                    }
            }
        }
        .edgePadding()
        .scrollIfLargerThanContainer(padding: 100)
    }

    // MARK: - Grid Item View

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
                UIDevice.impact(.light)
                router.route(to: \.userSignIn, server)
            }
            .environment(\.isEnabled, !isEditingUsers)
        }
    }

    // MARK: - List Content View

    @ViewBuilder
    private var listContentView: some View {
        ScrollView {
            LazyVStack {
                ForEach(gridItems, id: \.hashValue) { item in
                    listItemView(for: item)
                }
            }
        }
    }

    // MARK: - List Item View

    @ViewBuilder
    private func listItemView(for item: UserGridItem) -> some View {
        switch item {
        case let .user(user, server):
            UserRow(
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
            AddUserRow(
                serverSelection: $serverSelection,
                servers: viewModel.servers.keys
            ) { server in
                UIDevice.impact(.light)
                router.route(to: \.userSignIn, server)
            }
            .environment(\.isEnabled, !isEditingUsers)
        }
    }

    // MARK: - User View

    @ViewBuilder
    private var userView: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.clear
                    .onSizeChanged { size, _ in
                        contentSize = size
                    }

                switch userListDisplayType {
                case .grid:
                    if UIDevice.isPhone {
                        phoneGridContentView
                    } else {
                        padGridContentView
                    }
                case .list:
                    listContentView
                }
            }
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
                    viewModel: viewModel
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

    // MARK: - Empty View

    @ViewBuilder
    private var emptyView: some View {
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
        WrappedView {
            if viewModel.servers.isEmpty {
                emptyView
            } else {
                userView
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
                    if selectedUsers.count == users.count {
                        Button(L10n.removeAll) {
                            selectedUsers.removeAll()
                        }
                        .buttonStyle(.toolbarPill)
                    } else {
                        Button(L10n.selectAll) {
                            selectedUsers.insert(contentsOf: users)
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

            splashScreenImageSources = makeSplashScreenImageSources(
                serverSelection: serverSelection,
                allServersSelection: selectUserAllServersSplashscreen
            )
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
            if newValue {
                pin = ""
            } else {
                selectedUsers.removeAll()
            }
        }
        .onChange(of: selectUserAllServersSplashscreen) { newValue in
            splashScreenImageSources = makeSplashScreenImageSources(
                serverSelection: serverSelection,
                allServersSelection: newValue
            )
        }
        .onChange(of: serverSelection) { newValue in
            gridItems = makeGridItems(for: newValue)

            splashScreenImageSources = makeSplashScreenImageSources(
                serverSelection: newValue,
                allServersSelection: selectUserAllServersSplashscreen
            )
        }
        .onChange(of: viewModel.servers) { _ in
            gridItems = makeGridItems(for: serverSelection)
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
        .onNotification(.didChangeCurrentServerURL) { server in
            viewModel.send(.getServers)
            serverSelection = .server(id: server.id)
        }
        .onNotification(.didDeleteServer) { server in
            viewModel.send(.getServers)

            if case let SelectUserServerSelection.server(id: id) = serverSelection, server.id == id {
                if viewModel.servers.keys.count == 1, let first = viewModel.servers.keys.first {
                    serverSelection = .server(id: first.id)
                } else {
                    serverSelection = .all
                }
            }

            // change splash screen selection if necessary
            selectUserAllServersSplashscreen = serverSelection
        }
        .alert(
            Text(L10n.deleteUser),
            isPresented: $isPresentingConfirmDeleteUsers,
            presenting: selectedUsers
        ) { selectedUsers in
            Button(L10n.delete, role: .destructive) {
                viewModel.send(.deleteUsers(Array(selectedUsers)))
            }
        } message: { selectedUsers in
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
