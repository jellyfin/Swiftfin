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

    struct ListUserButton: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isSelected)
        private var isSelected

        private let item: UserItem?
        private let showServer: Bool
        private let action: () -> Void
        private let onDelete: (() -> Void)?

        private var isAddUser: Bool {
            item == nil
        }

        private var labelForegroundStyle: HierarchicalShapeStyle {
            if isAddUser {
                return isEnabled ? .primary : .secondary
            }
            guard isEditing else {
                return .primary
            }
            return isSelected ? .primary : .secondary
        }

        private var profileWidth: CGFloat {
            UIDevice.isTV ? 120 : 80
        }

        private var verticalPadding: CGFloat {
            UIDevice.isTV ? 16 : 8
        }

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                UserButtonImage(item)
                    .frame(width: profileWidth)
                    .padding(.vertical, verticalPadding)
            } content: {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item?.user.username ?? L10n.addUser)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(labelForegroundStyle)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if showServer, let item {
                            Text(item.server.name)
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.lightGray))
                        }
                    }

                    Spacer()

                    if !isAddUser {
                        ListRowCheckbox()
                    }
                }
                .padding(.horizontal, 0)
            }
            .isSeparatorVisible(!isAddUser)
            .onSelect(perform: action)
            .if(!isAddUser && !isEditing) { button in
                button
                    .contextMenu {
                        Button(
                            L10n.delete,
                            role: .destructive,
                            action: onDelete ?? {}
                        )
                    }
            }
        }
    }
}

extension SelectUserView.ListUserButton {

    // Add New User
    init(
        action: @escaping () -> Void
    ) {
        self.item = nil
        self.showServer = false
        self.action = action
        self.onDelete = nil
    }

    // Local User
    init(
        user: UserState,
        server: ServerState,
        showServer: Bool,
        action: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = (user: user, server: server)
        self.showServer = showServer
        self.action = action
        self.onDelete = onDelete
    }
}
