//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension SelectUserView {

    struct ListView: View {

        @AdaptiveLayout
        private var viewLayout

        @Binding
        private var isEditing: Bool
        @Binding
        private var selectedUsers: Set<UserState>

        private let users: [UserItem]
        private let serverSelection: SelectUserServerSelection
        private let action: (UserState) -> Void
        private let onDelete: (UserState) -> Void

        init(
            userItems: [UserItem],
            isEditing: Binding<Bool>,
            selectedUsers: Binding<Set<UserState>>,
            serverSelection: SelectUserServerSelection,
            action: @escaping (UserState) -> Void,
            onDelete: @escaping (UserState) -> Void
        ) {
            self.users = userItems
            self._isEditing = isEditing
            self._selectedUsers = selectedUsers
            self.serverSelection = serverSelection
            self.action = action
            self.onDelete = onDelete
        }

        var body: some View {
            List {
                ForEach(users, id: \.user.id) { item in
                    ChevronButton {
                        if isEditing {
                            selectedUsers.toggle(value: item.user)
                        } else {
                            action(item.user)
                        }
                    } label: {
                        HStack(spacing: viewLayout.edgePadding) {
                            UserProfileImage(
                                userID: item.user.id,
                                source: item.user.profileImageSource(
                                    client: item.server.client
                                ),
                                pipeline: .Swiftfin.local
                            )
                            .subtleShadow()
                            .frame(width: viewLayout.value(standard: viewLayout.value(compact: 50, regular: 80), large: 120))

                            VStack(alignment: .leading) {
                                Text(item.user.username)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .lineLimit(viewLayout.isAccessibilitySize ? nil : 1)
                                    .fixedSize(horizontal: false, vertical: true)

                                if serverSelection == .all {
                                    Text(item.server.name)
                                        .font(viewLayout.value(standard: .footnote, large: .body))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(viewLayout.isAccessibilitySize ? nil : 1)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .contextMenu {
                        if !isEditing {
                            Button(L10n.delete, role: .destructive) {
                                onDelete(item.user)
                            }
                        }
                    }
                    .isSelected(selectedUsers.contains(item.user))
                    #if os(tvOS)
                    .if(item.user.id == users.first?.user.id) { view in
                        view
                            .coordinatedFocus(Focus.focusedUserButton.rawValue)
                    }
                    #elseif os(iOS)
                    .swipeActions {
                        if !isEditing {
                            Button(
                                L10n.delete,
                                systemImage: "trash"
                            ) {
                                onDelete(item.user)
                            }
                            .tint(.red)
                        }
                    }
                    #endif
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            #if os(iOS)
            .scrollContentBackground(.hidden)
            #else
            .edgePadding()
            .scrollClipDisabled()
            .focusSection()
            #endif
        }
    }
}
