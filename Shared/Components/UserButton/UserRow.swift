//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct UserRow<Icon: View>: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    private let icon: Icon
    private let title: String
    private let subtitle: String?
    private let action: () -> Void
    private let onDelete: (() -> Void)?

    private var labelForegroundStyle: HierarchicalShapeStyle {
        if onDelete == nil {
            isEnabled ? .primary : .secondary
        } else {
            isSelected || !isEditing ? .primary : .secondary
        }
    }

    private var profileWidth: CGFloat {
        UIDevice.isTV ? 120 : 80
    }

    init(
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        @ViewBuilder icon: () -> Icon
    ) {
        self.icon = icon()
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.onDelete = onDelete
    }

    // MARK: - Body

    var body: some View {
        ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
            icon
                .frame(width: profileWidth)
                .padding(.vertical, profileWidth / 10)
        } content: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(labelForegroundStyle)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                }

                Spacer()

                if onDelete != nil {
                    ListRowCheckbox()
                }
            }
            .padding(.horizontal, 0)
        }
        .isSeparatorVisible(onDelete != nil)
        .onSelect(perform: action)
        .if(onDelete != nil && !isEditing) { row in
            row.contextMenu {
                if let onDelete {
                    Button(
                        L10n.delete,
                        role: .destructive,
                        action: onDelete
                    )
                }
            }
        }
    }
}

extension UserRow where Icon == AnyView {

    /// Local User - `SelectUserView`
    init(
        user: UserState,
        server: ServerState,
        showServer: Bool,
        action: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) where Icon == AnyView {
        self.init(
            title: user.username,
            subtitle: showServer ? server.name : nil,
            action: action,
            onDelete: onDelete
        ) {
            AnyView(
                UserProfileImage(
                    userID: user.id,
                    source: user.profileImageSource(
                        client: server.client
                    ),
                    pipeline: .Swiftfin.local
                )
                .posterShadow()
            )
        }
    }

    /// Public Server User - `UserSigninView`
    init(
        user: UserDto,
        client: JellyfinClient,
        action: @escaping () -> Void
    ) where Icon == AnyView {
        self.init(
            title: user.name ?? .emptyDash,
            action: action
        ) {
            AnyView(
                UserProfileImage(
                    userID: user.id,
                    source: user.profileImageSource(
                        client: client,
                        maxWidth: 120
                    )
                )
                .posterShadow()
            )
        }
    }
}
