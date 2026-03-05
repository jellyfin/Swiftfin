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

    struct UserActionButtonBar<AdvancedContent: View>: View {

        @Default(.selectUserServerSelection)
        private var serverSelection

        @Router
        private var router

        @Environment(\.horizontalSizeClass)
        private var horizontalSizeClass

        @Binding
        private var isEditingUsers: Bool
        @Binding
        private var selectedUsers: Set<UserState>
        @Binding
        private var isPresentingConfirmDeleteUsers: Bool

        private let servers: OrderedSet<ServerState>
        private let userItems: [UserItem]
        private let advancedContent: () -> AdvancedContent

        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }

        private var areUsersSelected: Bool {
            selectedUsers.isNotEmpty
        }

        private var areAllUsersSelected: Bool {
            selectedUsers.count == userItems.count
        }

        private var hasUsers: Bool {
            userItems.isNotEmpty
        }

        private var selectedServer: ServerState? {
            serverSelection.server(from: servers)
        }

        private var regularButtonHeight: CGFloat {
            UIDevice.isTV ? 100 : 75
        }

        init(
            servers: OrderedSet<ServerState>,
            isEditingUsers: Binding<Bool>,
            selectedUsers: Binding<Set<UserState>>,
            isPresentingConfirmDeleteUsers: Binding<Bool>,
            userItems: [UserItem],
            @ViewBuilder advancedContent: @escaping () -> AdvancedContent
        ) {
            self._isEditingUsers = isEditingUsers
            self._selectedUsers = selectedUsers
            self._isPresentingConfirmDeleteUsers = isPresentingConfirmDeleteUsers
            self.servers = servers
            self.userItems = userItems
            self.advancedContent = advancedContent
        }

        var body: some View {
            if isCompact {
                compactView
            } else {
                regularView
            }
        }

        private func toggleAllUsersSelected() {
            if areAllUsersSelected {
                selectedUsers.removeAll()
            } else {
                selectedUsers.insert(contentsOf: userItems.map(\.user))
            }
        }

        @ViewBuilder
        private var addUserContent: some View {
            ForEach(servers) { server in
                Button {
                    router.route(to: .userSignIn(server: server))
                } label: {
                    Text(server.name)
                    Text(server.currentURL.absoluteString)
                }
            }
        }

        // MARK: - Advanced Menu Content

        @ViewBuilder
        private var advancedMenuContent: some View {
            if hasUsers {
                Section {
                    ConditionalMenu(
                        tracking: selectedServer,
                        action: { server in
                            router.route(to: .userSignIn(server: server))
                        }
                    ) {
                        addUserContent
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

            advancedContent()
        }

        // MARK: - Server Menu

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

        // MARK: - Compact View

        @ViewBuilder
        private var compactView: some View {
            if !isEditingUsers {
                Menu {
                    serverMenuItems
                } label: {
                    serverMenuLabel
                        .padding()
                }
                .menuOrder(.fixed)
                #if os(iOS)
                    .buttonStyle(.material)
                #endif
                    .frame(height: 50)
                    .frame(maxWidth: 400)
                    .edgePadding([.bottom, .horizontal])
            }
        }

        // MARK: - Regular View

        private var regularView: some View {
            AlternateLayoutView(alignment: .top) {
                Color.clear
                    .frame(height: regularButtonHeight)
            } content: {
                HStack(alignment: .top, spacing: 30) {
                    if isEditingUsers {
                        editView
                    } else {
                        contentView
                    }
                }
                #if os(iOS)
                .buttonStyle(.material)
                #endif
                .animation(.easeInOut, value: areUsersSelected)
                .foregroundStyle(Color.primary)
            }
            .edgePadding([.bottom, .horizontal])
        }

        @ViewBuilder
        private var editView: some View {
            if areUsersSelected {
                Button(role: .destructive) {
                    isPresentingConfirmDeleteUsers = true
                } label: {
                    Text(L10n.delete)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .isSelected(true)
                #if os(iOS)
                    .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .primary))
                #endif
                    .frame(height: regularButtonHeight)
                    .frame(minWidth: 100, maxWidth: 400)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Button {
                toggleAllUsersSelected()
            } label: {
                Text(areAllUsersSelected ? L10n.removeAll : L10n.selectAll)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: regularButtonHeight)
            .frame(minWidth: 100, maxWidth: 400)

            Button {
                isEditingUsers = false
            } label: {
                Text(L10n.cancel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
                addUserContent
            } label: {
                Label(L10n.addUser, systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
            .menuOrder(.fixed)
            .frame(maxWidth: 600)
            .frame(height: regularButtonHeight)

            Menu {
                advancedMenuContent
            } label: {
                Label(L10n.advanced, systemImage: "gearshape.fill")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .menuOrder(.fixed)
            .frame(width: regularButtonHeight, height: regularButtonHeight)
        }
    }
}
