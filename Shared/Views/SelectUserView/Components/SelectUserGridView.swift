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

    struct GridView<AddUserButton: View>: PlatformView {

        @Environment(\.editMode)
        private var editMode

        @Binding
        private var selectedUsers: Set<UserState>

        private let userItems: [UserItem]
        private let serverSelection: SelectUserServerSelection
        private let onSelect: (UserState) -> Void
        private let onDelete: (UserState) -> Void
        private let addUserButton: () -> AddUserButton

        #if os(tvOS)
        @State
        private var scrollViewOffset: CGFloat = 0
        #endif

        private var columns: Int {
            UIDevice.isPhone ? 2 : 5
        }

        private var contentMaxWidth: CGFloat {
            min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        }

        init(
            userItems: [UserItem],
            selectedUsers: Binding<Set<UserState>>,
            serverSelection: SelectUserServerSelection,
            onSelect: @escaping (UserState) -> Void,
            onDelete: @escaping (UserState) -> Void,
            @ViewBuilder addUserButton: @escaping () -> AddUserButton
        ) {
            self.userItems = userItems
            self._selectedUsers = selectedUsers
            self.serverSelection = serverSelection
            self.onSelect = onSelect
            self.onDelete = onDelete
            self.addUserButton = addUserButton
        }

        @ViewBuilder
        private func userGridButton(for item: UserItem) -> some View {
            UserButton(
                user: item.user,
                server: item.server,
                showServer: serverSelection == .all
            ) {
                if editMode?.wrappedValue.isEditing == true {
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
            Group {
                if userItems.isEmpty {
                    addUserButton()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    CenteredLazyVGrid(
                        data: userItems,
                        id: \.user.id,
                        columns: columns,
                        spacing: EdgeInsets.edgePadding
                    ) { item in
                        userGridButton(for: item)
                    }
                }
            }
            .edgePadding(UIDevice.isPhone ? [.horizontal, .vertical] : .horizontal)
            .scrollIfLargerThanContainer(axes: .vertical, padding: 100)
            .frame(maxWidth: contentMaxWidth)
        }

        var tvOSView: some View {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 300)

                HStack(spacing: EdgeInsets.edgePadding) {
                    if userItems.isEmpty {
                        addUserButton()
                            .frame(width: 300)
                    }

                    ForEach(userItems, id: \.user.id) { item in
                        userGridButton(for: item)
                            .frame(width: 300)
                    }
                }
                .edgePadding(.horizontal)
                .focusSection()
            }
            .scrollIfLargerThanContainer(axes: .horizontal, padding: 100)
            #if os(tvOS)
                .scrollViewOffset($scrollViewOffset)
                .animation(.linear(duration: 0.1), value: scrollViewOffset)
            #endif
        }
    }
}
