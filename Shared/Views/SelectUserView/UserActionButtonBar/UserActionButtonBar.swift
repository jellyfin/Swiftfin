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

    struct UserActionButtonBar: View {

        @Environment(\.editMode)
        private var editMode
        @Environment(\.horizontalSizeClass)
        private var horizontalSizeClass

        @Binding
        private var selectedUsers: Set<UserState>

        private let servers: OrderedSet<ServerState>
        private let allUsers: [UserItem]
        private let onDelete: () -> Void

        private func toggleUsers() {
            if selectedUsers.count == allUsers.count {
                selectedUsers.removeAll()
            } else {
                selectedUsers = Set(allUsers.map(\.user))
            }
        }

        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }

        private var buttonHeight: CGFloat {
            switch horizontalSizeClass {
            case .compact:
                50
            default:
                UIDevice.isTV ? 100 : 75
            }
        }

        init(
            servers: OrderedSet<ServerState>,
            allUsers: [UserItem],
            selectedUsers: Binding<Set<UserState>>,
            onDelete: @escaping () -> Void
        ) {
            self.servers = servers
            self.allUsers = allUsers
            self._selectedUsers = selectedUsers
            self.onDelete = onDelete
        }

        var body: some View {
            if isCompact {
                compactView
            } else {
                regularView
            }
        }

        // MARK: - iOS View

        @ViewBuilder
        private var compactView: some View {
            if editMode?.wrappedValue.isEditing == false {
                ServerMenu(servers: servers)
                    .buttonStyle(.material)
                    .frame(height: buttonHeight)
                    .frame(maxWidth: 400)
                    .edgePadding([.bottom, .horizontal])
            }
        }

        // MARK: - iPadOS / tvOS Views

        private var regularView: some View {
            AlternateLayoutView(alignment: .top) {
                Color.clear
                    .frame(height: buttonHeight)
            } content: {
                HStack(alignment: .top, spacing: 30) {
                    if editMode?.wrappedValue.isEditing == true {
                        editView
                    } else {
                        contentView
                    }
                }
                #if os(iOS)
                .buttonStyle(.material)
                #endif
                .animation(.easeInOut, value: selectedUsers.isNotEmpty)
                .foregroundStyle(Color.primary)
            }
            .edgePadding([.bottom, .horizontal])
        }

        @ViewBuilder
        private var editView: some View {
            if selectedUsers.isNotEmpty {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text(L10n.delete)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                #if os(iOS)
                .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .primary))
                .isSelected(true)
                #endif
                .frame(height: buttonHeight)
                .frame(minWidth: 100, maxWidth: 400)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Button {
                toggleUsers()
            } label: {
                Text(selectedUsers.count == allUsers.count ? L10n.removeAll : L10n.selectAll)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: buttonHeight)
            .frame(minWidth: 100, maxWidth: 400)

            Button {
                editMode?.wrappedValue = .inactive
            } label: {
                Text(L10n.cancel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: buttonHeight)
            .frame(minWidth: 100, maxWidth: 400)
        }

        @ViewBuilder
        private var contentView: some View {
            AddUserMenu(servers: servers)
                .labelStyle(.iconOnly)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .menuOrder(.fixed)
                .frame(width: buttonHeight, height: buttonHeight)
                .hidden(allUsers.isEmpty)

            ServerMenu(servers: servers)
                .frame(maxWidth: 600)
                .frame(height: buttonHeight)

            Menu {
                Section {
                    EditUsersMenu(hasUsers: !allUsers.isEmpty)
                        .environment(\.editMode, editMode)
                }
                AdvancedMenu()
            } label: {
                Label(L10n.advanced, systemImage: "gearshape.fill")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .menuOrder(.fixed)
            .frame(width: buttonHeight, height: buttonHeight)
        }
    }
}
