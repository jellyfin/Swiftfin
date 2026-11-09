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

    struct Toolbar: View {

        @AdaptiveLayout
        private var viewLayout

        @ScaledMetric(relativeTo: .body)
        private var labelHeight = 20.0

        @Binding
        private var isEditing: Bool
        @Binding
        private var selectedUsers: Set<UserState>

        @FocusState
        private var isCenterButtonFocused: Bool

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

        private var buttonHeight: CGFloat {
            viewLayout.value(
                standard: max(viewLayout.controlHeight, labelHeight + 24),
                large: viewLayout.controlHeight
            )
        }

        init(
            servers: OrderedSet<ServerState>,
            allUsers: [UserItem],
            isEditing: Binding<Bool>,
            selectedUsers: Binding<Set<UserState>>,
            onDelete: @escaping () -> Void
        ) {
            self.servers = servers
            self.allUsers = allUsers
            self._isEditing = isEditing
            self._selectedUsers = selectedUsers
            self.onDelete = onDelete
        }

        var body: some View {
            if viewLayout.isCompact {
                compactView
            } else {
                regularView
            }
        }

        @ViewBuilder
        private var compactView: some View {
            if !isEditing {
                HStack(spacing: 16) {
                    ServerMenu(servers: servers)
                        .frame(minHeight: buttonHeight)
                        .frame(maxWidth: 400)

                    AddUserMenu(servers: servers)
                        .frame(width: buttonHeight, height: buttonHeight)
                }
                .edgePadding([.bottom, .horizontal])
            }
        }

        private var regularView: some View {
            HStack(alignment: .top, spacing: viewLayout.value(standard: nil, large: 32)) {
                if isEditing {
                    editView
                } else {
                    regularContentView
                }
            }
            .animation(.linear(duration: 0.1), value: selectedUsers.isNotEmpty)
            .frame(minHeight: buttonHeight)
            .frame(maxWidth: .infinity)
            .focusSection()
            .edgePadding([.bottom, .horizontal])
            .defaultFocus(
                $isCenterButtonFocused,
                true,
                priority: .userInitiated
            )
        }

        @ViewBuilder
        private var editView: some View {
            Button(action: toggleUsers) {
                Text(selectedUsers.count == allUsers.count ? L10n.removeAll : L10n.selectAll)
                    .frame(maxWidth: .infinity, minHeight: buttonHeight)
            }
            .frame(minWidth: 100, maxWidth: 300)

            Button {
                isEditing = false
            } label: {
                Text(L10n.cancel)
                    .frame(maxWidth: .infinity, minHeight: buttonHeight)
            }
            .frame(minWidth: 100, maxWidth: 300)
            .focused($isCenterButtonFocused)

            Button(role: .destructive, action: onDelete) {
                Text(L10n.delete)
                    .frame(maxWidth: .infinity, minHeight: buttonHeight)
            }
            .frame(minWidth: 100, maxWidth: 300)
            .disabled(selectedUsers.isEmpty)
        }

        @ViewBuilder
        private var regularContentView: some View {
            Menu {
                AdvancedMenuContent(
                    hasUsers: allUsers.isNotEmpty,
                    isEditing: $isEditing
                )
            } label: {
                Label(L10n.advanced, systemImage: "gearshape.fill")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .foregroundStyle(.primary, .secondary)
            .menuOrder(.fixed)
            .symbolRenderingMode(.monochrome)
            .frame(width: buttonHeight, height: buttonHeight)
            .buttonBorderShape(.circle)
            .backport
            .glassEffect(in: .circle)

            ServerMenu(servers: servers)
                .frame(maxWidth: viewLayout.value(standard: 400, large: 600))
                .frame(minHeight: buttonHeight)
                .focused($isCenterButtonFocused)

            AddUserMenu(servers: servers)
                .frame(width: buttonHeight, height: buttonHeight)
                .hidden(allUsers.isEmpty)
        }
    }
}
