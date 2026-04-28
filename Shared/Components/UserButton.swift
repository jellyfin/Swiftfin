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

struct UserButton: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    private let image: UserProfileImage
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

    var body: some View {
        Button(action: action) {
            labelView
        }
        .contextMenu {
            if let onDelete, !isEditing {
                Button(
                    L10n.delete,
                    role: .destructive,
                    action: onDelete
                )
            }
        }
        .foregroundStyle(.primary, .secondary)
        #if os(tvOS)
            .buttonStyle(.borderless)
            .backport
            .buttonBorderShape(.circle)
        #endif
    }

    @ViewBuilder
    private var labelView: some View {
        // tvOS breaks HoverEffects when using a VStack
        #if os(tvOS)
        imageView

        titleView
        #else
        VStack {
            imageView

            titleView
        }
        #endif
    }

    @ViewBuilder
    private var imageView: some View {
        image
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

        AlternateLayoutView {
            // swiftlint:disable:next hard_coded_display_string
            Text("Hidden")
        } content: {
            if let subtitle {
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
    }
}

extension UserButton {

    init(
        user: UserState,
        server: ServerState,
        showServer: Bool,
        action: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.init(
            image: .init(
                userID: user.id,
                source: user.profileImageSource(
                    client: server.client
                ),
                pipeline: .Swiftfin.local
            ),
            title: user.username,
            subtitle: showServer ? server.name : nil,
            action: action,
            onDelete: onDelete
        )
    }

    init(
        user: UserDto,
        client: JellyfinClient,
        action: @escaping () -> Void
    ) {
        self.init(
            image: .init(
                userID: user.id,
                source: user.profileImageSource(
                    client: client,
                    maxWidth: 240
                ),
                pipeline: .Swiftfin.local
            ),
            title: user.name ?? .emptyDash,
            subtitle: nil,
            action: action,
            onDelete: nil
        )
    }
}
