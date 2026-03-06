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

    @Router
    private var router

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.editMode)
    private var editMode

    @State
    private var pin: String = ""
    @State
    private var selectedUsers: Set<UserState> = []

    @State
    private var isPresentingConfirmDeleteUsers = false
    @State
    private var isPresentingLocalPin: Bool = false

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
            return viewModel
                .servers
                .keys
                .shuffled()
                .map(\.splashScreenImageSource)

        case let (.server(id), _), let (.all, .server(id)):
            guard let server = viewModel
                .servers
                .keys
                .first(where: { $0.id == id }) else { return [] }

            return [server.splashScreenImageSource]
        }
    }

    private var userItems: [UserItem] {
        let items: [UserItem] = {
            switch serverSelection {
            case .all:
                return viewModel.servers
                    .map { server, users in
                        users.map { (server: server, user: $0) }
                    }
                    .flatMap(\.self)
                    .map { UserItem(user: $0.user, server: $0.server) }
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

    // MARK: - Add User Grid Button

    @ViewBuilder
    private func addUserGridButton() -> some View {
        #if os(tvOS)
        UserButton {
            if let selectedServer {
                addUser(server: selectedServer)
            }
        }
        .if(selectedServer == nil) { button in
            button.contextMenu {
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
        #else
        ConditionalMenu(
            tracking: selectedServer,
            action: addUser
        ) {
            Text(L10n.selectServer)

            ForEach(viewModel.servers.keys) { server in
                Button {
                    addUser(server: server)
                } label: {
                    Text(server.name)
                    Text(server.currentURL.absoluteString)
                }
            }
        } label: {
            UserButton {
                if let selectedServer {
                    addUser(server: selectedServer)
                }
            }
        }
        .buttonStyle(.plain)
        #endif
    }

    // MARK: - Shared Alert Content

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
        TextField(L10n.pin, text: $pin)
            .keyboardType(.numberPad)

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

    // MARK: - Splash Screen Background

    @ViewBuilder
    private var splashScreenBackground: some View {
        if selectUserUseSplashscreen, splashScreenImageSources.isNotEmpty {
            ZStack {
                ImageView(splashScreenImageSources)
                    .pipeline(.Swiftfin.local)
                    .aspectRatio(contentMode: .fill)
                    .id(splashScreenImageSources)
                    .transition(.opacity.animation(.linear(duration: 0.1)))
                    .animation(.linear, value: splashScreenImageSources)

                Color.black
                    .opacity(0.9)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var contentView: some View {
        ZStack {
            if viewModel.servers.isEmpty {
                InitialSetupView()
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        if userListDisplayType == .list, userItems.isNotEmpty {
                            ListView(
                                userItems: userItems,
                                selectedUsers: $selectedUsers,
                                serverSelection: serverSelection,
                                onSelect: { select(user: $0) },
                                onDelete: { delete(user: $0) }
                            )
                        } else {
                            GridView(
                                userItems: userItems,
                                selectedUsers: $selectedUsers,
                                serverSelection: serverSelection,
                                onSelect: { select(user: $0) },
                                onDelete: { delete(user: $0) }
                            ) {
                                addUserGridButton()
                            }
                        }
                    }
                    .animation(.linear(duration: 0.1), value: userListDisplayType)
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

                    UserActionButtonBar(
                        servers: viewModel.servers.keys,
                        allUsers: userItems,
                        selectedUsers: $selectedUsers,
                        onDelete: {
                            isPresentingConfirmDeleteUsers = true
                        }
                    )
                    .focusSection()
                }
            }
        }
        .environment(\.editMode, editMode)
        .isEditing(editMode?.wrappedValue.isEditing == true)
        .environment(\.isOverComplexContent, true)
        .background { splashScreenBackground }
    }

    // MARK: - Shared Modifiers

    private func applySharedModifiers(_ view: some View) -> some View {
        view
            .onAppear {
                viewModel.getServers()
            }
            .onChange(of: editMode) { _, newValue in
                guard !newValue.isEditing else { return }
                selectedUsers.removeAll()
            }
            .onChange(of: viewModel.servers.keys) { newValue in
                onServersChanged(newValue)
            }
            .onChange(of: isPresentingLocalPin) { newValue in
                if newValue {
                    pin = ""
                } else {
                    selectedUsers.removeAll()
                }
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
            .alert(L10n.signIn, isPresented: $isPresentingLocalPin) {
                pinAlertContent
            } message: {
                pinAlertMessage
            }
            .errorMessage($viewModel.error)
    }

    // MARK: - iOS Body

    #if os(iOS)
    private var iOSBody: some View {
        applySharedModifiers(
            contentView
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

                    if horizontalSizeClass == .compact {
                        ToolbarItem(placement: .topBarLeading) {
                            if editMode.wrappedValue.isEditing == true {
                                Button(areAllUsersSelected ? L10n.removeAll : L10n.selectAll) {
                                    toggleAllUsersSelected()
                                }
                                .buttonStyle(.toolbarPill)
                            }
                        }

                        ToolbarItemGroup(placement: .topBarTrailing) {
                            if editMode.isEditing {
                                Button(L10n.cancel) {
                                    editMode = .inactive
                                }
                                .buttonStyle(.toolbarPill)
                            } else {
                                Menu {
                                    NewUserMenu(
                                        servers: viewModel.servers.keys,
                                        hasUsers: userItems.isNotEmpty
                                    )
                                    .environment(\.editMode, editMode)

                                    AdvancedMenu()
                                } label: {
                                    Label(L10n.advanced, systemImage: "gearshape.fill")
                                }
                            }
                        }

                        ToolbarItem(placement: .bottomBar) {
                            if editMode.isEditing {
                                Button(L10n.delete) {
                                    isPresentingConfirmDeleteUsers = true
                                }
                                .buttonStyle(.toolbarPill(.red))
                                .disabled(selectedUsers.isEmpty)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                }
                .onChange(of: isPresentingConfirmDeleteUsers) { newValue in
                    guard !newValue else { return }
                    editMode.wrappedValue = .inactive
                    selectedUsers.removeAll()
                }
                .onReceive(viewModel.$error) { error in
                    guard error != nil else { return }
                    UIDevice.feedback(.error)
                }
                .alert(
                    L10n.delete,
                    isPresented: $isPresentingConfirmDeleteUsers
                ) {
                    Button(L10n.delete, role: .destructive) {
                        viewModel.deleteUsers(selectedUsers)
                        selectedUsers.removeAll()
                        editMode.wrappedValue = .inactive
                    }
                } message: {
                    deleteConfirmationMessage
                }
        )
    }
    #endif

    // MARK: - tvOS Body

    #if os(tvOS)
    private var tvOSBody: some View {
        applySharedModifiers(
            contentView
                .ignoresSafeArea()
                .navigationBarBranding()
                .confirmationDialog(
                    Text(L10n.deleteUser),
                    isPresented: $isPresentingConfirmDeleteUsers
                ) {
                    Button(L10n.delete, role: .destructive) {
                        viewModel.deleteUsers(selectedUsers)
                        selectedUsers.removeAll()
                        editMode = .inactive
                    }
                } message: {
                    deleteConfirmationMessage
                }
        )
    }
    #endif

    // MARK: - Body

    var body: some View {
        #if os(iOS)
        iOSBody
        #elseif os(tvOS)
        tvOSBody
        #endif
    }
}
