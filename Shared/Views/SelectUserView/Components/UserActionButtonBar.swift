//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct UserActionButtonBar: View {

        @Default(.selectUserDisplayType)
        private var userListDisplayType
        @Default(.selectUserSortOrder)
        private var userSortOrder

        @Router
        private var router

        @Environment(\.isEditing)
        private var isEditing

        @Binding
        private var serverSelection: SelectUserServerSelection

        private let areUsersSelected: Bool
        private let hasUsers: Bool
        private let isCompact: Bool
        private let selectedServer: ServerState?
        private let servers: OrderedSet<ServerState>
        private let onDelete: () -> Void
        private let onEditingChanged: (Bool) -> Void
        private let toggleAllUsersSelected: () -> Void

        init(
            isCompact: Bool,
            serverSelection: Binding<SelectUserServerSelection>,
            selectedServer: ServerState?,
            servers: OrderedSet<ServerState>,
            areUsersSelected: Bool,
            hasUsers: Bool,
            onDelete: @escaping () -> Void,
            onEditingChanged: @escaping (Bool) -> Void,
            toggleAllUsersSelected: @escaping () -> Void
        ) {
            self._serverSelection = serverSelection
            self.areUsersSelected = areUsersSelected
            self.hasUsers = hasUsers
            self.isCompact = isCompact
            self.selectedServer = selectedServer
            self.servers = servers
            self.onDelete = onDelete
            self.onEditingChanged = onEditingChanged
            self.toggleAllUsersSelected = toggleAllUsersSelected
        }

        var body: some View {
            if isCompact {
                compactView
            } else {
                regularView
            }
        }

        @ViewBuilder
        private var serverMenuItems: some View {
            Section {
                Button(L10n.addServer, systemImage: "plus") {
                    router.route(to: .connectToServer)
                }

                if let selectedServer {
                    Button(L10n.editServer, systemImage: "server.rack") {
                        router.route(
                            to: .editServer(server: selectedServer, isEditing: true),
                            style: .sheet
                        )
                    }
                }
            }

            Picker(L10n.servers, selection: $serverSelection) {

                if servers.count > 1 {
                    Label(L10n.allServers, systemImage: "person.2.fill")
                        .tag(SelectUserServerSelection.all)
                }

                ForEach(servers) { server in
                    VStack(alignment: .leading) {
                        Text(server.name)
                            .foregroundStyle(Color.primary)

                        Text(server.currentURL.absoluteString)
                            .foregroundStyle(Color.secondary)
                    }
                    .tag(SelectUserServerSelection.server(id: server.id))
                }
            }
        }

        @ViewBuilder
        private var serverMenuLabel: some View {
            HStack(spacing: isCompact ? nil : 16) {
                switch serverSelection {
                case .all:
                    Label(L10n.allServers, systemImage: "person.2.fill")
                case let .server(id):
                    if let server = servers.first(where: { $0.id == id }) {
                        Label(server.name, systemImage: "server.rack")
                    } else {
                        Label(L10n.unknown, systemImage: "server.rack")
                    }
                }

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.subheadline.weight(.semibold))
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.primary)
        }

        @ViewBuilder
        private var compactView: some View {
            if !isEditing {
                Menu {
                    serverMenuItems
                } label: {
                    serverMenuLabel
                        .padding()
                }
                .menuOrder(.fixed)
                .frame(height: 50)
                .frame(maxWidth: 400)
                .edgePadding([.bottom, .horizontal])
            }
        }

        private var regularButtonHeight: CGFloat {
            UIDevice.isTV ? 100 : 75
        }

        private var regularView: some View {
            AlternateLayoutView(alignment: .top) {
                Color.clear
                    .frame(height: regularButtonHeight)
            } content: {
                HStack(alignment: .top, spacing: 30) {
                    if isEditing {
                        editView
                    } else {
                        contentView
                    }
                }
                .animation(.easeInOut, value: areUsersSelected)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)
            }
            .edgePadding([.bottom, .horizontal])
        }

        @ViewBuilder
        private var editView: some View {
            if areUsersSelected {
                Button(
                    L10n.delete,
                    role: .destructive,
                    action: onDelete
                )
                .isSelected(true)
                .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .primary))
                .frame(height: regularButtonHeight)
                .frame(minWidth: 100, maxWidth: 400)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Button {
                toggleAllUsersSelected()
            } label: {
                Text(areUsersSelected ? L10n.removeAll : L10n.selectAll)
            }
            .buttonStyle(.material)
            .frame(height: regularButtonHeight)
            .frame(minWidth: 100, maxWidth: 400)

            Button {
                onEditingChanged(false)
            } label: {
                Text(L10n.cancel)
            }
            .buttonStyle(.material)
            .frame(height: regularButtonHeight)
            .frame(minWidth: 100, maxWidth: 400)
        }

        @ViewBuilder
        private var contentView: some View {
            ConditionalMenu(
                tracking: selectedServer,
                action: { server in
                    router.route(to: .userSignIn(server: server))
                }
            ) {
                Text(L10n.selectServer)

                ForEach(servers) { server in
                    Button {
                        router.route(to: .userSignIn(server: server))
                    } label: {
                        Text(server.name)
                        Text(server.currentURL.absoluteString)
                    }
                }
            } label: {
                Label(L10n.addUser, systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.material)
            .menuOrder(.fixed)
            .frame(width: regularButtonHeight, height: regularButtonHeight)
            .hidden(!hasUsers)

            Menu {
                serverMenuItems
            } label: {
                serverMenuLabel
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.material)
            .menuOrder(.fixed)
            .frame(maxWidth: 600)
            .frame(height: regularButtonHeight)

            Menu {
                Section {
                    Button(L10n.editUsers, systemImage: "person.crop.circle") {
                        onEditingChanged(true)
                    }
                }

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

                Picker(selection: $userSortOrder) {
                    ForEach(SelectUserSortOrder.allCases, id: \.hashValue) {
                        Label($0.displayTitle, systemImage: $0.systemImage)
                            .tag($0)
                    }
                } label: {
                    Text(L10n.sort)
                    Text(userSortOrder.displayTitle)
                    Image(systemName: userSortOrder.systemImage)
                }
                .pickerStyle(.menu)

                Section {
                    Button(L10n.advanced, systemImage: "gearshape.fill") {
                        router.route(to: .appSettings)
                    }
                }
            } label: {
                Label(L10n.advanced, systemImage: "gearshape.fill")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.material)
            .menuOrder(.fixed)
            .frame(width: regularButtonHeight, height: regularButtonHeight)
        }
    }
}
