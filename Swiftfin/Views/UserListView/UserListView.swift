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

// TODO: option for splashscreen image
// TODO: navigation bar blur fixed with splashscreen

struct UserListView: View {

    private enum UserGridItem: Hashable {
        case user(UserState)
        case addUser
    }

    @Default(.userListDisplayType)
    private var userListDisplayType

    @EnvironmentObject
    private var router: UserListCoordinator.Router

    @State
    private var gridItems: OrderedSet<UserGridItem> = []
    @State
    private var selectedServer: ServerState?
    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var viewModel = UserListViewModel()

    init() {

        let initialDisplayType = Defaults[.userListDisplayType]

        self.layout = Self.phoneLayout(displayType: initialDisplayType)
    }

    private var splashScreenImageSource: ImageSource? {
        guard let selectedServer else { return nil }

        let parameters = Paths.GetSplashscreenParameters(maxHeight: 1000)
        let request = Paths.getSplashscreen(parameters: parameters)

        guard let url = selectedServer.client.fullURL(with: request) else { return nil }

        return ImageSource(url: url)
    }

    private static func phoneLayout(
        displayType: LibraryDisplayType
    ) -> CollectionVGridLayout {
        switch displayType {
        case .grid:
            .minWidth(
                120,
                insets: EdgeInsets.edgeInsets,
                itemSpacing: EdgeInsets.edgePadding * 2,
                lineSpacing: EdgeInsets.edgePadding * 2
            )
        case .list:
            .columns(1)
        }
    }

    private var advancedMenu: some View {
        Menu(L10n.advanced, systemImage: "gearshape.fill") {
//            Section {
//                Button("Edit Users", systemImage: "person.crop.circle") {}
//            }

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

//            Picker(selection: .constant(1)) {
//                Button("Name", systemImage: "abc") {}
//                    .tag(1)
//
//                Button("Last Signed In", systemImage: "clock.fill") {}
//                    .tag(2)
//            } label: {
//                Text("Sort")
//                Text("Last Signed In")
//                Image(systemName: "clock.fill")
//            }
//            .pickerStyle(.menu)

            Section {
                Button(L10n.advanced, systemImage: "gearshape.fill") {}
            }
        }
    }

    @ViewBuilder
    private func gridView(for item: UserGridItem) -> some View {
        switch item {
        case let .user(user):
            UserProfileButton(
                user: .init(id: user.id, name: user.username),
                client: .init(
                    configuration: .init(
                        url: URL(string: "apple.com")!,
                        client: "",
                        deviceName: "",
                        deviceID: "",
                        version: ""
                    )
                )
            )
            .onSelect {
                viewModel.send(.signIn(user))
            }
        case .addUser:
            AddUserButton {
                print("here")
            }
        }
    }

    @ViewBuilder
    private func listView(for item: UserGridItem) -> some View {
        switch item {
        case let .user(user):
            UserListRow(
                user: .init(id: user.id, name: user.username),
                client: .init(
                    configuration: .init(
                        url: URL(string: "apple.com")!,
                        client: "",
                        deviceName: "",
                        deviceID: "",
                        version: ""
                    )
                )
            )
            .onSelect {
                viewModel.send(.signIn(user))
            }
        case .addUser:
            AddUserListRow()
                .onSelect {
                    print("Add User")
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        CollectionVGrid(
            $gridItems,
            layout: $layout
        ) { item in
            switch userListDisplayType {
            case .grid:
                gridView(for: item)
            case .list:
                listView(for: item)
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
        .onChange(of: userListDisplayType) { newValue in
            layout = Self.phoneLayout(displayType: newValue)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(uiImage: .jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 34)
            }
        }
        .topBarTrailing {
            advancedMenu

            Button("", systemImage: "heart.fill") {
                router.route(to: \.connectToServer)
            }
        }
        .onAppear {
            viewModel.send(.getServers)
        }
        .onChange(of: viewModel.servers) { newValue in
            guard let server = newValue.keys.first else { return }
            let items = newValue[server]!.map { UserGridItem.user($0) }
                .appending(.addUser)

            gridItems = OrderedSet(items)

            selectedServer = server
        }
    }
}
