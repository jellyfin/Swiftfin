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

#warning("TODO: cleanup")

// TODO: option for splashscreen image
// TODO: navigation bar blur always on with splashscreen

extension Defaults.Keys {

    static let userListViewServerSelectionOption = Defaults.Key<UserListView.ServerSelection>(
        "userListViewServerSelectionOption",
        default: .all,
        suite: .universalSuite
    )

    static let userListViewUseSplashScreen = Defaults.Key<Bool>(
        "userListViewUseSplashScreen",
        default: false,
        suite: .universalSuite
    )
}

extension ServerState {

    func splashScreenImageSource() -> ImageSource {
        let request = Paths.getSplashscreen()
        return ImageSource(url: client.fullURL(with: request))
    }
}

struct UserListView: View {

    enum ServerSelection: RawRepresentable, Codable, Defaults.Serializable, Equatable, Hashable {

        case all
        case server(id: String)

        var rawValue: String {
            switch self {
            case .all:
                "swiftfin-all"
            case let .server(id):
                id
            }
        }

        init?(rawValue: String) {
            switch rawValue {
            case "swiftfin-all":
                self = .all
            default:
                self = .server(id: rawValue)
            }
        }
    }

    private enum UserGridItem: Hashable {
        case user(UserState, server: ServerState)
        case addUser
    }

    @Default(.userListViewServerSelectionOption)
    private var serverSelection
    @Default(.userListDisplayType)
    private var userListDisplayType
    @Default(.userListViewUseSplashScreen)
    private var userListViewUseSplashScreen

    @EnvironmentObject
    private var router: UserListCoordinator.Router

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
    private var viewModel = UserListViewModel()

    private var selectedServer: ServerState? {
        if case let ServerSelection.server(id: id) = serverSelection,
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

    private func makeGridItems(for serverSelection: ServerSelection) -> OrderedSet<UserGridItem> {
        switch serverSelection {
        case .all:
            let items = viewModel.servers
                .map { server, users in
                    users.map { UserGridItem.user($0, server: server) }
                }
                .flatMap { $0 }
                .appending(.addUser)

            return OrderedSet(items)
        case let .server(id: id):
            guard let server = viewModel.servers.keys.first(where: { server in server.id == id }) else {
                assertionFailure("server with ID not found?")
                return [.addUser]
            }

            let items = viewModel.servers[server]!
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

            Section {
                Button(L10n.advanced, systemImage: "gearshape.fill") {
                    router.route(to: \.advancedSettings)
                }
            }
        }
    }

    // MARK: grid

    @ViewBuilder
    private var gridContentView: some View {
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
        .scroll(ifLargerThan: contentSize.height)
    }

    @ViewBuilder
    private func gridItemView(for item: UserGridItem) -> some View {
        switch item {
        case let .user(user, server):
            UserGridButton(
                user: user,
                client: server.client
            ) {
                if isEditingUsers {
                    selectedUsers.toggle(value: user)
                } else {
                    viewModel.send(.signIn(user))
                }
            }
            .environment(\.isSelected, selectedUsers.contains(user))
            .environment(\.isEditing, isEditingUsers)
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
                server: server
            ) {
                if isEditingUsers {
                    selectedUsers.toggle(value: user)
                } else {
                    viewModel.send(.signIn(user))
                }
            }
            .environment(\.isSelected, selectedUsers.contains(user))
            .environment(\.isEditing, isEditingUsers)
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
            viewModel.send(.getServers)

            isEditingUsers = false
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.red)

                Label("Delete", systemImage: "trash.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(selectedUsers.isNotEmpty ? .primary : .secondary)

                if selectedUsers.isEmpty {
                    Color.black
                        .opacity(0.5)
                }
            }
            .frame(height: 50)
        }
        .disabled(!isEditingUsers)
        .buttonStyle(.plain)
    }

    // MARK: userView

    @ViewBuilder
    private var userView: some View {
        VStack {
            ZStack {
                Color.clear
                    .trackingSize($contentSize)

                switch userListDisplayType {
                case .grid:
                    gridContentView
                case .list:
                    listContentView
                }
            }
            .frame(maxHeight: .infinity)

            if !isEditingUsers {
                ServerSelectionMenu(selection: $serverSelection, viewModel: viewModel)
                    .edgePadding()
            }

            if isEditingUsers {
                deleteUsersButton
                    .edgePadding()
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
                    .id(splashScreenImageSource)
            }
        }
        .alwaysNavigationBarBlur()
    }

    // MARK: emptyView

    private var emptyView: some View {
        VStack {}
    }

    // MARK: body

    var body: some View {
        WrappedView {
            switch viewModel.state {
            case let .error(error):
                Text(error.localizedDescription)
            case .initial:
                Color.black
            case .content:
                if viewModel.servers.isEmpty {
                    emptyView
                } else {
                    userView
                }
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
                Button(L10n.cancel) {
                    isEditingUsers = false
                }
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
    }
}

#warning("TODO: cleanup")

struct ScrollIfLargerThanModifier: ViewModifier {

    @State
    private var contentSize: CGSize = .zero

    let height: CGFloat

    func body(content: Content) -> some View {
        ScrollView {
            content
                .trackingSize($contentSize)
        }
        .backport
        .scrollDisabled(contentSize.height < height)
        .frame(maxHeight: contentSize.height >= height ? .infinity : contentSize.height)
    }
}

extension View {

    func scroll(ifLargerThan height: CGFloat) -> some View {
        modifier(ScrollIfLargerThanModifier(height: height))
    }
}
