//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import OrderedCollections
import SwiftUI

#warning("TODO: option for splashscreen image")

// TODO: user ordering

struct SelectUserView: View {

    private enum UserGridItem: Hashable {
        case user(UserState, server: ServerState)
        case addUser
    }

    @Default(.selectUserServerSelection)
    private var serverSelection
    @Default(.selectUserDisplayType)
    private var userListDisplayType
//    @Default(.userListViewUseSplashScreen)
//    private var userListViewUseSplashScreen

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @State
    private var contentSafeAreaInsets: EdgeInsets = .zero
    @State
    private var contentSize: CGSize = .zero
    @State
    private var gridItemSize: CGSize = .zero
    @State
    private var gridItems: OrderedSet<UserGridItem> = []
    @State
    private var isEditingUsers: Bool = false
    @State
    private var selectedUsers: Set<UserState> = []

    @StateObject
    private var viewModel = SelectUserViewModel()

    private var selectedServer: ServerState? {
        if case let SelectUserServerSelection.server(id: id) = serverSelection,
           let server = viewModel.servers.keys.first(where: { server in server.id == id })
        {
            return server
        }

        return nil
    }

    private var splashScreenImageSource: ImageSource? {
        switch serverSelection {
        case .all:
            return viewModel.servers
                .keys
                .randomElement()?
                .splashScreenImageSource()
        case .server:
            return selectedServer?
                .splashScreenImageSource()
        }
    }

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

    // MARK: advancedMenu

    @ViewBuilder
    private var advancedMenu: some View {
        Menu(L10n.advanced, systemImage: "gearshape.fill") {

            Section {
                if gridItems.count > 1 {
                    Button("Edit Users", systemImage: "person.crop.circle") {
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
                    Text("Layout")
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

    // MARK: grid

    #warning("TODO: centering")
    @ViewBuilder
    private var padGridContentView: some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: 150, maximum: 300), spacing: EdgeInsets.edgePadding)]) {
            ForEach(gridItems, id: \.hashValue) { item in
                gridItemView(for: item)
            }
        }
        .edgePadding()
        .scroll(ifLargerThan: contentSize.height - 100) // do a little less
    }

    @ViewBuilder
    private var phoneGridContentView: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: EdgeInsets.edgePadding), GridItem(.flexible())]) {
            ForEach(gridItems, id: \.hashValue) { item in
                gridItemView(for: item)
                    .if(gridItems.count % 2 == 1 && item == gridItems.last) { view in
                        view.trackingSize($gridItemSize)
                            .offset(x: (contentSize.width / 2) - (gridItemSize.width / 2) - EdgeInsets.edgePadding)
                    }
            }
        }
        .edgePadding()
        .scroll(ifLargerThan: contentSize.height - 100) // do a little less
    }

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
                    viewModel.send(.signIn(user))
                }
            } onDelete: {
                viewModel.send(.deleteUsers([user]))
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

    // MARK: list

    @ViewBuilder
    private var listContentView: some View {
        ScrollView {
            LazyVStack {
                ForEach(gridItems, id: \.hashValue) { item in
                    listItemView(for: item)
                }
            }
            .edgePadding()
        }
    }

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
                    viewModel.send(.signIn(user))
                }
            } onDelete: {
                viewModel.send(.deleteUsers([user]))
            }
            .environment(\.isEditing, isEditingUsers)
            .environment(\.isSelected, selectedUsers.contains(user))
        case .addUser:
            AddUserRow(
                serverSelection: $serverSelection,
                servers: viewModel.servers.keys
            ) { server in
                router.route(to: \.userSignIn, server)
            }
            .environment(\.isEnabled, !isEditingUsers)
        }
    }

    private var deleteUsersButton: some View {
        Button {
            viewModel.send(.deleteUsers(Array(selectedUsers)))

            isEditingUsers = false
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.red)

                Text("Delete")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(selectedUsers.isNotEmpty ? .primary : .secondary)

                if selectedUsers.isEmpty {
                    Color.black
                        .opacity(0.5)
                }
            }
            .frame(height: 50)
            .frame(maxWidth: 400)
        }
        .disabled(selectedUsers.isEmpty)
        .buttonStyle(.plain)
    }

    // MARK: userView

    @ViewBuilder
    private var userView: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.clear
                    .onSizeChanged { size, safeAreaInsets in
                        contentSize = size
                        contentSafeAreaInsets = safeAreaInsets
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

            if isEditingUsers {
                deleteUsersButton
                    .edgePadding([.bottom, .horizontal])
            }
        }
        .background {
            if let splashScreenImageSource {
                ImageView(splashScreenImageSource)
                    .placeholder { _ in
                        Color.clear
                    }
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .overlay {
                        Color.black
                            .opacity(0.9)
                            .ignoresSafeArea()
                    }
            }
        }
    }

    // MARK: emptyView

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

    // MARK: body

    var body: some View {
        WrappedView {
            if viewModel.servers.isEmpty {
                emptyView
            } else {
                userView
            }
        }
        .navigationTitle("Users")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(uiImage: .jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30)
            }
        }
        .topBarTrailing {
            if isEditingUsers {
                Button {
                    isEditingUsers = false
                } label: {
                    L10n.cancel.text
                        .font(.headline)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.tertiarySystemBackground)
                        }
                }
                .buttonStyle(.plain)
            } else {
                advancedMenu
            }
        }
        .onAppear {
            viewModel.send(.getServers)
        }
        .onChange(of: isEditingUsers) { newValue in
            guard !newValue else { return }
            selectedUsers.removeAll()
        }
        .onChange(of: serverSelection) { newValue in
            gridItems = makeGridItems(for: newValue)
        }
        .onChange(of: viewModel.servers) { _ in
            gridItems = makeGridItems(for: serverSelection)
        }
        .onNotification(.didConnectToServer) { notification in
            if let server = notification.object as? ServerState {
                viewModel.send(.getServers)
                serverSelection = .server(id: server.id)
            }
        }
        .onNotification(.didChangeCurrentServerURL) { notification in
            if let server = notification.object as? ServerState {
                viewModel.send(.getServers)
                serverSelection = .server(id: server.id)
            }
        }
        .onNotification(.didDeleteServer) { notification in
            if let server = notification.object as? ServerState {
                if case let SelectUserServerSelection.server(id: id) = serverSelection, server.id == id {
                    serverSelection = .all
                }

                viewModel.send(.getServers)
            }
        }
    }
}
