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

#if os(iOS)
import LocalAuthentication
#endif

// TODO: user ordering
//       - name
//       - last signed in date

struct SelectUserView: PlatformView {

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

    // MARK: - State & Environment Objects

    @Router
    private var router

    @State
    private var isEditingUsers: Bool = false
    @State
    private var pin: String = ""
    @State
    private var selectedUsers: Set<UserState> = []

    #if os(tvOS)
    @State
    private var scrollViewOffset: CGFloat = 0
    #endif

    // MARK: - Dialog States

    @State
    private var isPresentingConfirmDeleteUsers = false
    @State
    private var isPresentingLocalPin: Bool = false

    @StateObject
    private var viewModel = SelectUserViewModel()

    // MARK: - Shared Computed Properties

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
                .flatMap(\.self)
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

    // MARK: - Shared Functions

    private func addUserSelected(server: ServerState) {
        #if os(iOS)
        UIDevice.impact(.light)
        #endif
        router.route(to: .userSignIn(server: server))
    }

    private func delete(user: UserState) {
        selectedUsers.insert(user)
        isPresentingConfirmDeleteUsers = true
    }

    private func select(user: UserState, needsPin: Bool = true) {
        selectedUsers.insert(user)

        #if os(iOS)
        Task { @MainActor in
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

            await viewModel.signIn(user, pin: pin)
        }
        #else
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

        viewModel.signIn(user, pin: pin)
        #endif
    }

    private func onServersChanged(_ newValue: OrderedSet<ServerState>) {
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

    private func onSignedIn(_ user: UserState) {
        Defaults[.lastSignedInUserID] = .signedIn(userID: user.id)
        Container.shared.currentUserSession.reset()
        UIDevice.feedback(.success)
        Notifications[.didSignIn].post()
    }

    // MARK: - Perform Device Authentication

    #if os(iOS)
    // error logging/presentation is handled within here, just
    // use try+thrown error in local Task for early return
    private func performDeviceAuthentication(reason: String) async throws {
        let context = LAContext()
        var policyError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            viewModel.logger.critical("\(policyError!.localizedDescription)")
            await viewModel.error(ErrorMessage(L10n.unableToPerformDeviceAuthFaceID))
            throw ErrorMessage(L10n.deviceAuthFailed)
        }

        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            viewModel.logger.critical("\(error.localizedDescription)")
            await viewModel.error(ErrorMessage(L10n.unableToPerformDeviceAuth))
            throw ErrorMessage(L10n.deviceAuthFailed)
        }
    }
    #endif

    @ViewBuilder
    private func addUserButtonView(displayType: LibraryDisplayType) -> some View {
        AddUserButton(
            displayType: displayType,
            selectedServer: selectedServer,
            servers: viewModel.servers.keys,
            action: addUserSelected
        )
    }

    @ViewBuilder
    private func userButtonView(for item: UserItem, displayType: LibraryDisplayType) -> some View {
        let user = item.user
        let server = item.server

        UserButton(
            displayType: displayType,
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
        .isSelected(selectedUsers.contains(user))
    }

    // MARK: - Shared Alerts

    @ViewBuilder
    private var deleteConfirmationMessage: some View {
        if selectedUsers.count == 1, let first = selectedUsers.first {
            Text(L10n.deleteUserSingleConfirmation(first.username))
        } else {
            Text(L10n.deleteUserMultipleConfirmation(selectedUsers.count))
        }
    }

    @ViewBuilder
    private var pinAlertContent: some View {
        #if os(iOS)
        TextField(L10n.pin, text: $pin)
            .keyboardType(.numberPad)
        #else
        // TODO: Verify on tvOS 18
        // https://forums.developer.apple.com/forums/thread/739545
        // TextField(L10n.pin, text: $pin)
        TextField(text: $pin) {}
            .keyboardType(.numberPad)
        #endif

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
    }

    @ViewBuilder
    private var pinAlertMessage: some View {
        if let user = selectedUsers.first, user.pinHint.isNotEmpty {
            Text(user.pinHint)
        } else {
            let username = selectedUsers.first?.username ?? .emptyDash

            Text(L10n.enterPinForUser(username))
        }
    }

    // MARK: - iOS Helper Views

    #if os(iOS)

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
                    router.route(to: .appSettings)
                }
            }
        }
    }

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
                addUserButtonView(displayType: .grid)
            }
        } else {
            CenteredLazyVGrid(
                data: userItems,
                id: \.user.id,
                minimum: 150,
                maximum: 300,
                spacing: EdgeInsets.edgePadding
            ) { item in
                userButtonView(for: item, displayType: .grid)
            }
        }
    }

    @ViewBuilder
    private var phoneGridContentView: some View {
        if userItems.isEmpty {
            CenteredLazyVGrid(
                data: [0],
                id: \.self,
                columns: 2
            ) { _ in
                addUserButtonView(displayType: .grid)
            }
        } else {
            CenteredLazyVGrid(
                data: userItems,
                id: \.user.id,
                columns: 2,
                spacing: EdgeInsets.edgePadding
            ) { item in
                userButtonView(for: item, displayType: .grid)
            }
            .edgePadding()
        }
    }

    @ViewBuilder
    private var listContentView: some View {
        List {
            let userItems = self.userItems

            if userItems.isEmpty {
                addUserButtonView(displayType: .list)
                    .listRowBackground(EmptyView())
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
            }

            ForEach(userItems, id: \.user.id) { item in
                userButtonView(for: item, displayType: .list)
                    .isSelected(selectedUsers.contains(item.user))
                    .swipeActions {
                        if !isEditingUsers {
                            Button(
                                L10n.delete,
                                systemImage: "trash"
                            ) {
                                delete(user: item.user)
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

    @ViewBuilder
    private var iOSContentView: some View {
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
            .environment(\.isOverComplexContent, true)
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

            SelectUserBottomBar(
                serverSelection: $serverSelection,
                selectedServer: selectedServer,
                servers: viewModel.servers.keys,
                areUsersSelected: selectedUsers.isNotEmpty,
                hasUsers: userItems.isNotEmpty
            ) {
                isPresentingConfirmDeleteUsers = true
            } onEditingChanged: { editing in
                isEditingUsers = editing
            } toggleAllUsersSelected: {
                if selectedUsers.isNotEmpty {
                    selectedUsers.removeAll()
                } else {
                    selectedUsers.insert(contentsOf: userItems.map(\.user))
                }
            }
        }
        .isEditing(isEditingUsers)
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

    #else

    @ViewBuilder
    private var tvOSContentView: some View {
        VStack {
            VStack(spacing: 0) {

                Color.clear
                    .frame(height: 100)

                Group {
                    if userItems.isEmpty {
                        CenteredLazyVGrid(
                            data: [0],
                            id: \.self,
                            columns: 5
                        ) { _ in
                            addUserButtonView(displayType: .grid)
                        }
                    } else {
                        CenteredLazyVGrid(
                            data: userItems,
                            id: \.user.id,
                            columns: 5,
                            spacing: EdgeInsets.edgePadding
                        ) { item in
                            userButtonView(for: item, displayType: .grid)
                                .isSelected(selectedUsers.contains(item.user))
                        }
                    }
                }
                .focusSection()
            }
            .scrollIfLargerThanContainer(padding: 100)
            .scrollViewOffset($scrollViewOffset)

            SelectUserBottomBar(
                serverSelection: $serverSelection,
                selectedServer: selectedServer,
                servers: viewModel.servers.keys,
                areUsersSelected: selectedUsers.isNotEmpty,
                hasUsers: userItems.isNotEmpty
            ) {
                isPresentingConfirmDeleteUsers = true
            } onEditingChanged: { editing in
                isEditingUsers = editing
            } toggleAllUsersSelected: {
                if selectedUsers.isNotEmpty {
                    selectedUsers.removeAll()
                } else {
                    selectedUsers.insert(contentsOf: userItems.map(\.user))
                }
            }
            .focusSection()
        }
        .isEditing(isEditingUsers)
        .animation(.linear(duration: 0.1), value: scrollViewOffset)
        .environment(\.isOverComplexContent, true)
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

    #endif

    // MARK: - iOS View

    var iOSView: some View {
        ZStack {
            if viewModel.servers.isEmpty {
                VStack(spacing: 10) {
                    Text(L10n.connectToJellyfinServerStart)
                        .frame(minWidth: 50, maxWidth: 240)
                        .multilineTextAlignment(.center)

                    Button(L10n.connect) {
                        router.route(to: .connectToServer)
                    }
                    .foregroundStyle(
                        accentColor.overlayColor,
                        accentColor
                    )
                    .buttonStyle(.primary)
                    .frame(height: 50)
                    .frame(maxWidth: 300)
                }
            } else {
                #if os(iOS)
                iOSContentView
                #endif
            }
        }
        #if os(iOS)
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
        #endif
        .onAppear {
                viewModel.getServers()
            }
            .onChange(of: isEditingUsers) { newValue in
                guard !newValue else { return }
                selectedUsers.removeAll()
            }
            .onChange(of: isPresentingLocalPin) { newValue in
                if newValue {
                    pin = ""
                }
            }
        #if os(iOS)
            .onChange(of: isPresentingConfirmDeleteUsers) { newValue in
                guard !newValue else { return }
                isEditingUsers = false
                selectedUsers.removeAll()
            }
            .onReceive(viewModel.$error) { error in
                guard error != nil else { return }
                UIDevice.feedback(.error)
            }
        #endif
            .onChange(of: viewModel.servers.keys) { newValue in
                    onServersChanged(newValue)
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
        #if os(iOS)
                .alert(
                    L10n.delete,
                    isPresented: $isPresentingConfirmDeleteUsers
                ) {
                    Button(L10n.delete, role: .destructive) {
                        viewModel.deleteUsers(selectedUsers)
                    }
                } message: {
                    deleteConfirmationMessage
                }
        #endif
                .alert(L10n.signIn, isPresented: $isPresentingLocalPin) {
                        pinAlertContent
                    } message: {
                        pinAlertMessage
                    }
                    .errorMessage($viewModel.error)
    }

    // MARK: - tvOS View

    var tvOSView: some View {
        ZStack {
            if viewModel.servers.isEmpty {
                VStack(spacing: 50) {
                    Text(L10n.connectToJellyfinServerStart)
                        .font(.body)
                        .frame(minWidth: 50, maxWidth: 500)
                        .multilineTextAlignment(.center)

                    Button {
                        router.route(to: .connectToServer)
                    } label: {
                        Text(L10n.connect)
                            .font(.callout)
                            .fontWeight(.bold)
                            .frame(width: 400, height: 75)
                            .background(accentColor)
                    }
                    .buttonStyle(.card)
                }
            } else {
                #if os(tvOS)
                tvOSContentView
                #endif
            }
        }
        #if os(tvOS)
        .ignoresSafeArea()
        .navigationBarBranding()
        #endif
        .onAppear {
            viewModel.getServers()
        }
        .onChange(of: isEditingUsers) { newValue in
            guard !newValue else { return }
            selectedUsers.removeAll()
        }
        .onChange(of: isPresentingLocalPin) { newValue in
            if newValue {
                pin = ""
            } else {
                selectedUsers.removeAll()
            }
        }
        .onChange(of: viewModel.servers.keys) { newValue in
            onServersChanged(newValue)
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
        #if os(tvOS)
        .confirmationDialog(
            Text(L10n.deleteUser),
            isPresented: $isPresentingConfirmDeleteUsers
        ) {
            Button(L10n.delete, role: .destructive) {
                viewModel.deleteUsers(selectedUsers)
            }
        } message: {
            deleteConfirmationMessage
        }
        #endif
        .alert(L10n.signIn, isPresented: $isPresentingLocalPin) {
                pinAlertContent
            } message: {
                pinAlertMessage
            }
            .errorMessage($viewModel.error)
    }
}
