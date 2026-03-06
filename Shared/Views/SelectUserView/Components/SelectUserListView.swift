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

        @Environment(\.editMode)
        private var editMode

        @Binding
        private var selectedUsers: Set<UserState>

        private let userItems: [UserItem]
        private let serverSelection: SelectUserServerSelection
        private let onSelect: (UserState) -> Void
        private let onDelete: (UserState) -> Void

        private var profileImageWidth: CGFloat {
            UIDevice.isTV ? 120 : UIDevice.isPad ? 80 : 50
        }

        init(
            userItems: [UserItem],
            selectedUsers: Binding<Set<UserState>>,
            serverSelection: SelectUserServerSelection,
            onSelect: @escaping (UserState) -> Void,
            onDelete: @escaping (UserState) -> Void
        ) {
            self.userItems = userItems
            self._selectedUsers = selectedUsers
            self.serverSelection = serverSelection
            self.onSelect = onSelect
            self.onDelete = onDelete
        }

        @ViewBuilder
        var body: some View {
            List {
                ForEach(userItems, id: \.user.id) { item in
                    ChevronButton {
                        if editMode?.wrappedValue.isEditing == true {
                            selectedUsers.toggle(value: item.user)
                        } else {
                            onSelect(item.user)
                        }
                    } label: {
                        LabeledContent {
                            EmptyView()
                        } label: {
                            HStack(spacing: EdgeInsets.edgePadding) {
                                UserProfileImage(
                                    userID: item.user.id,
                                    source: item.user.profileImageSource(
                                        client: item.server.client
                                    ),
                                    pipeline: .Swiftfin.local
                                )
                                .posterShadow()
                                .frame(width: profileImageWidth)

                                VStack(alignment: .leading) {
                                    Text(item.user.username)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)

                                    if serverSelection == .all {
                                        Text(item.server.name)
                                            .font(UIDevice.isTV ? .body : .footnote)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                    .contextMenu {
                        if editMode?.wrappedValue.isEditing != true {
                            Button(L10n.delete, role: .destructive) {
                                onDelete(item.user)
                            }
                        }
                    }
                    .isSelected(selectedUsers.contains(item.user))
                    #if os(iOS)
                        .swipeActions {
                            if editMode?.wrappedValue.isEditing != true {
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
                .scrollClipDisabled()
                .edgePadding()
            #endif
        }
    }
}
