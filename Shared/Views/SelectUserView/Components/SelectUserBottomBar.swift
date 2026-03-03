//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct SelectUserBottomBar: PlatformView {

        @Environment(\.isEditing)
        private var isEditing

        @Router
        private var router

        @Binding
        private var serverSelection: SelectUserServerSelection

        private let areUsersSelected: Bool
        private let hasUsers: Bool
        private let selectedServer: ServerState?
        private let servers: OrderedSet<ServerState>

        private let onDelete: () -> Void
        private let onEditingChanged: (Bool) -> Void
        private let toggleAllUsersSelected: () -> Void

        init(
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
            self.selectedServer = selectedServer
            self.servers = servers
            self.onDelete = onDelete
            self.onEditingChanged = onEditingChanged
            self.toggleAllUsersSelected = toggleAllUsersSelected
        }

        var iOSView: some View {
            if !isEditing {
                ServerSelectionMenu(
                    selection: $serverSelection,
                    selectedServer: selectedServer,
                    servers: servers
                )
                .frame(height: 50)
                .frame(maxWidth: 400)
                .edgePadding([.bottom, .horizontal])
            }
        }

        var tvOSView: some View {
            AlternateLayoutView(alignment: .top) {
                Color.clear
                    .frame(height: 100)
            } content: {
                HStack(alignment: .top, spacing: 30) {
                    if isEditing {
                        editView
                    } else {
                        contentView
                    }
                }
                .animation(.easeInOut, value: areUsersSelected)
                .edgePadding(.horizontal)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.primary)
            }
            .edgePadding(.bottom)
        }

        @ViewBuilder
        private var editView: some View {
            if areUsersSelected {
                Button(
                    L10n.delete,
                    action: onDelete
                )
                .isSelected(true)
                .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .primary))
                .frame(height: 100)
                .frame(minWidth: 100, maxWidth: 400)
            }

            Button {
                toggleAllUsersSelected()
            } label: {
                Text(areUsersSelected ? L10n.removeAll : L10n.selectAll)
            }
            .buttonStyle(.material)
            .frame(height: 100)
            .frame(minWidth: 100, maxWidth: 400)

            Button {
                onEditingChanged(false)
            } label: {
                Text(L10n.cancel)
            }
            .buttonStyle(.material)
            .frame(height: 100)
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
            }
            .buttonStyle(.material)
            .menuOrder(.fixed)
            .frame(width: 100, height: 100)
            .hidden(!hasUsers)

            ServerSelectionMenu(
                selection: $serverSelection,
                selectedServer: selectedServer,
                servers: servers
            )
            .frame(maxWidth: 600)
            .frame(height: 100)

            Menu {
                Section {
                    Button(L10n.editUsers, systemImage: "person.crop.circle") {
                        onEditingChanged(true)
                    }
                }

                Section {
                    Button(L10n.advanced, systemImage: "gearshape.fill") {
                        router.route(to: .appSettings)
                    }
                }
            } label: {
                Label(L10n.advanced, systemImage: "gearshape.fill")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.material)
            .menuOrder(.fixed)
            .frame(width: 100, height: 100)
        }
    }
}
