//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI
import OrderedCollections
import SwiftUI

// TODO: user deletion

struct SelectUserView: View {

    private enum UserGridItem: Hashable {
        case user(UserState, server: ServerState)
        case addUser
    }

    @Default(.selectUserServerSelection)
    private var serverSelection

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @State
    private var contentSize: CGSize = .zero
    @State
    private var error: Error? = nil
    @State
    private var gridItems: OrderedSet<UserGridItem> = []
    @State
    private var gridItemSize: CGSize = .zero
    @State
    private var isPresentingError: Bool = false
    @State
    private var isPresentingServers: Bool = false
    @State
    private var padGridItemColumnCount: Int = 1
    @State
    private var scrollViewOffset: CGFloat = 0
    @State
    private var splashScreenImageSource: ImageSource? = nil

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

    // MARK: grid

    private func gridItemOffset(index: Int) -> CGFloat {
        let lastRowIndices = (gridItems.count - gridItems.count % padGridItemColumnCount ..< gridItems.count)

        guard lastRowIndices.contains(index) else { return 0 }

        let lastRowMissing = padGridItemColumnCount - gridItems.count % padGridItemColumnCount
        return CGFloat(lastRowMissing) * (gridItemSize.width + EdgeInsets.edgePadding) / 2
    }

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

    @ViewBuilder
    private func gridItemView(for item: UserGridItem) -> some View {
        switch item {
        case let .user(user, server):
            UserGridButton(
                user: user,
                server: server,
                showServer: serverSelection == .all
            ) {
//                if isEditingUsers {
//                    selectedUsers.toggle(value: user)
//                } else {
                viewModel.send(.signIn(user, pin: ""))
//                }
            } onDelete: {
//                selectedUsers.insert(user)
//                isPresentingConfirmDeleteUsers = true
            }
//            .environment(\.isEditing, isEditingUsers)
//            .environment(\.isSelected, selectedUsers.contains(user))
        case .addUser:
            AddUserButton(
                serverSelection: $serverSelection,
                servers: viewModel.servers.keys
            ) { server in
                router.route(to: \.userSignIn, server)
            }
        }
    }

    // MARK: userView

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
                }
                .scrollIfLargerThanContainer(padding: 100)
                .scrollViewOffset($scrollViewOffset)
            }

            HStack {
                ServerSelectionMenu(
                    selection: $serverSelection,
                    viewModel: viewModel
                )
            }
        }
        .animation(.linear(duration: 0.1), value: scrollViewOffset)
        .background {
            if let splashScreenImageSource {
                ZStack {
                    Color.clear

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

    // MARK: emptyView

    @ViewBuilder
    private var emptyView: some View {
        ZStack {
            VStack {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .edgePadding()

                Color.clear
            }

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
    }

    var body: some View {
        ZStack {
            if viewModel.servers.isEmpty {
                emptyView
            } else {
                userView
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.send(.getServers)

            splashScreenImageSource = makeSplashScreenImageSource(
                serverSelection: serverSelection,
                allServersSelection: .all
            )

//            gridItems = OrderedSet(
//                (0 ..< 20)
//                    .map { i in
//                        UserState(accessToken: "", id: "\(i)", serverID: "", username: "\(i)")
//                    }
//                    .map { u in
//                        UserGridItem.user(u, server: .init(urls: [], currentURL: URL(string: "/")!, name: "Test", id: "", usersIDs: []))
//                    }
//            )
        }
        .onChange(of: serverSelection) { _, newValue in
            gridItems = makeGridItems(for: newValue)

            splashScreenImageSource = makeSplashScreenImageSource(
                serverSelection: newValue,
                allServersSelection: .all
            )
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
                self.isPresentingError = true
            case let .signedIn(user):
                Defaults[.lastSignedInUserID] = .signedIn(userID: user.id)
                Container.shared.currentUserSession.reset()
                Notifications[.didSignIn].post()
            }
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
            viewModel.send(.getServers)

            if let server = notification.object as? ServerState {
                if case let SelectUserServerSelection.server(id: id) = serverSelection, server.id == id {
                    if viewModel.servers.keys.count == 1, let first = viewModel.servers.keys.first {
                        serverSelection = .server(id: first.id)
                    } else {
                        serverSelection = .all
                    }
                }

                // change splash screen selection if necessary
//                selectUserAllServersSplashscreen = serverSelection
            }
        }
    }
}
