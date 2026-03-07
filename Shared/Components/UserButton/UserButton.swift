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

struct UserButton<Icon: View>: View {

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

    var body: some View {
        Button(action: action) {
            labelView
        }
        .if(onDelete != nil && !isEditing) { button in
            button.contextMenu {
                if let onDelete {
                    Button(
                        L10n.delete,
                        role: .destructive,
                        action: onDelete
                    )
                }
            }
        }
        #if os(iOS)
        .buttonStyle(.plain)
        #else
        .buttonStyle(.borderless)
        .backport
        .buttonBorderShape(.circle)
        .foregroundStyle(.primary, .secondary)
        #endif
    }

    @ViewBuilder
    private var labelView: some View {
        // iOS places these horizontally by default
        // tvOS breaks HoverEffects when using a VStack
        #if os(tvOS)
        iconView
        titleView
        #else
        VStack {
            iconView
            titleView
        }
        #endif
    }

    @ViewBuilder
    private var iconView: some View {
        icon
            .hoverEffect(.highlight)
            .overlay(alignment: .bottomTrailing) {
                if onDelete != nil, isEditing, isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: UIDevice.isTV ? 75 : 40,
                            height: UIDevice.isTV ? 75 : 40
                        )
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(accentColor.overlayColor, accentColor)
                        .hoverEffect(.lift)
                }
            }
    }

    @ViewBuilder
    private var titleView: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(labelForegroundStyle)
            .lineLimit(1)

        if let subtitle {
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        } else {
            // For layout, not to be localized
            Text("Hidden")
                .font(.footnote)
                .hidden()
        }
    }
}

extension UserButton where Icon == AnyView {

    /// Add User - `SelectUserView`
    init(
        action: @escaping () -> Void
    ) where Icon == AnyView {
        self.init(
            title: L10n.addUser,
            action: action
        ) {
            AnyView(
                RelativeSystemImageView(systemName: "plus")
                    .foregroundStyle(Color.secondary)
                    .background(.thinMaterial)
                    .clipShape(.circle)
                    .aspectRatio(1, contentMode: .fit)
                    .posterShadow()
            )
        }
    }

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
                        maxWidth: 240
                    )
                )
                .posterShadow()
            )
        }
    }
}
