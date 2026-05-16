//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: remember last focused user for tvOS focus

extension SelectUserView {

    struct GridView: PlatformView {

        @Binding
        private var isEditing: Bool
        @Binding
        private var selectedUsers: Set<UserState>

        private let onDelete: (UserState) -> Void
        private let onSelect: (UserState) -> Void
        private let serverSelection: SelectUserServerSelection
        private let userItems: [UserItem]

        init(
            userItems: [UserItem],
            isEditing: Binding<Bool>,
            selectedUsers: Binding<Set<UserState>>,
            serverSelection: SelectUserServerSelection,
            onSelect: @escaping (UserState) -> Void,
            onDelete: @escaping (UserState) -> Void
        ) {
            self.userItems = userItems
            self._isEditing = isEditing
            self._selectedUsers = selectedUsers
            self.serverSelection = serverSelection
            self.onSelect = onSelect
            self.onDelete = onDelete
        }

        @ViewBuilder
        private func userGridButton(for item: UserItem) -> some View {
            UserButton(
                user: item.user,
                server: item.server,
                showServer: serverSelection == .all
            ) {
                if isEditing {
                    selectedUsers.toggle(value: item.user)
                } else {
                    onSelect(item.user)
                }
            } onDelete: {
                onDelete(item.user)
            }
            .isSelected(selectedUsers.contains(item.user))
        }

        var iOSView: some View {
            CenteredLazyVGrid(
                data: userItems,
                id: \.user.id,
                columns: UIDevice.isPhone ? 2 : 5,
                spacing: EdgeInsets.edgePadding
            ) { item in
                userGridButton(for: item)
            }
            .edgePadding(UIDevice.isPhone ? [.horizontal, .vertical] : .horizontal)
            .scrollIfLargerThanContainer(axes: .vertical, padding: 100)
        }

        var tvOSView: some View {
            HStack(spacing: EdgeInsets.edgePadding) {
                ForEach(userItems, id: \.user.id) { item in
                    userGridButton(for: item)
                        .frame(width: 300)
                }
            }
            .edgePadding(.horizontal)
            .focusSection()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollIfLargerThanContainer(axes: .horizontal)
            #if os(tvOS)
                .scrollClipDisabled()
            #endif
        }
    }
}
