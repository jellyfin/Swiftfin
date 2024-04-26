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

    static let userListViewServerSelectionOption = Defaults.Key<UserListView.ServerSelectionOption>(
        "userListViewServerSelectionOption",
        default: .none,
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

    // Note: `none` necessary since Defaults doesn't support `nil`
    enum ServerSelectionOption: RawRepresentable, Codable, Defaults.Serializable, Equatable, Hashable {

        case all
        case server(id: String)
        case none

        var rawValue: String {
            switch self {
            case .all:
                "swiftfin-all"
            case .none:
                "swiftfin-none"
            case let .server(id):
                id
            }
        }

        init?(rawValue: String) {
            switch rawValue {
            case "swiftfin-all":
                self = .all
            case "swiftfin-none":
                self = .none
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
    private var storedServerSelectionOption
    @Default(.userListDisplayType)
    private var userListDisplayType

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

    @State
    private var isSelectingServer: Bool = false

    @StateObject
    private var viewModel = UserListViewModel()

    private var splashScreenImageSource: ImageSource? {
        switch storedServerSelectionOption {
        case .all:
            return viewModel.servers
                .keys
                .randomElement()?
                .splashScreenImageSource()
        case .none:
            return nil
        case let .server(id: id):
            return viewModel.servers
                .keys
                .first(where: { $0.id == id })?
                .splashScreenImageSource()
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

                if storedServerSelectionOption != .all || storedServerSelectionOption != .all {
                    Button("Edit Server", systemImage: "server.rack") {
                        print("edit server")
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
                            .offset(x: (contentSize.width / 2) - (gridItemSize.width / 2) - 10)
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
            UserGridItemView(
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
            AddUserButton {
                // TODO: figure out what to do here with `all`
                //       - open menu to select server
                switch storedServerSelectionOption {
                case .all: ()
                case .none: ()
                case let .server(id: id):
                    router.route(to: \.userSignIn, viewModel.servers.keys.first(where: { $0.id == id })!)
                }
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
            UserListRow(
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
            AddUserListRow {
                switch storedServerSelectionOption {
                case .all: ()
                case .none: ()
                case let .server(id: id):
                    router.route(to: \.userSignIn, viewModel.servers.keys.first(where: { $0.id == id })!)
                }
            }
            .environment(\.isEnabled, !isEditingUsers)
        }
    }

    // MARK: contentView

    @ViewBuilder
    private var contentView: some View {
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

            if storedServerSelectionOption != .none, !isEditingUsers {
                ServerSelectionMenu(selection: $storedServerSelectionOption) {
                    Section {
                        Button("Add Server", systemImage: "plus") {
                            router.route(to: \.connectToServer)
                        }
                    }

                    Picker("Servers", selection: $storedServerSelectionOption) {
                        ForEach(viewModel.servers.keys) { server in
                            Button {} label: {
                                Text(server.name)
                                Text(server.currentURL.absoluteString)
                            }
                            .tag(ServerSelectionOption.server(id: server.id))
                        }

                        Text("All")
                            .tag(ServerSelectionOption.all)
                    }
                }
                .edgePadding()
            }

            if isEditingUsers {
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

    // MARK: body

    var body: some View {
        WrappedView {
            switch viewModel.state {
            case let .error(error):
                Text(error.localizedDescription)
            case .initial:
                Color.black
            case .content:
                contentView
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
                Button("Cancel") {
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
        .onChange(of: storedServerSelectionOption) { newValue in
            switch newValue {
            case .all:
                print("all")
                let items = viewModel.servers
                    .map { server, users in
                        users.map { UserGridItem.user($0, server: server) }
                    }
                    .flatMap { $0 }
                    .appending(.addUser)

                gridItems = OrderedSet(items)
            case .none:
                print("none - onChange(storedServerSelectionOption")
            case let .server(id: id):
                print("server: \(id)")
                guard let server = viewModel.servers.keys.first(where: { server in server.id == id }) else {
                    assertionFailure("server with ID not found?")
                    return
                }

                let items = viewModel.servers[server]!
                    .map { UserGridItem.user($0, server: server) }
                    .appending(.addUser)

                gridItems = OrderedSet(items)
            }
        }
        .onChange(of: viewModel.servers) { _ in
            switch storedServerSelectionOption {
            case .all:
                let items = viewModel.servers
                    .map { server, users in
                        users.map { UserGridItem.user($0, server: server) }
                    }
                    .flatMap { $0 }
                    .appending(.addUser)

                gridItems = OrderedSet(items)
            case .none:
                storedServerSelectionOption = .all
            case let .server(id: id):
                print("server: \(id)")
                guard let server = viewModel.servers.keys.first(where: { server in server.id == id }) else {
                    assertionFailure("server with ID not found?")
                    return
                }

                let items = viewModel.servers[server]!
                    .map { UserGridItem.user($0, server: server) }
                    .appending(.addUser)

                gridItems = OrderedSet(items)
            }
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

struct ServerSelectionMenu<Content: View>: View {

    @Binding
    private var selection: UserListView.ServerSelectionOption

    private let content: () -> Content

    init(selection: Binding<UserListView.ServerSelectionOption>, @ViewBuilder _ content: @escaping () -> Content) {
        self._selection = selection
        self.content = content
    }

    var body: some View {
        Menu {
            content()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.secondarySystemFill)
                    .opacity(0.75)

                Group {
                    switch selection {
                    case .all:
                        Text("all")
                    case let .server(id):
                        Text(id)
                    case .none:
                        Text("None")
                    }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.secondary)
            }
            .frame(height: 50)
        }
        .buttonStyle(.plain)
    }
}

extension Set {

    mutating func toggle(value: Element) {
        if contains(value) {
            remove(value)
        } else {
            insert(value)
        }
    }
}
