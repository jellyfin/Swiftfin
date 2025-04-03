//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButton<Content: View>: View {

        // MARK: - Environment Objects

        @Environment(\.isSelected)
        private var isSelected

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        private let content: () -> Content
        private let icon: String
        private let isCompact: Bool
        private let selectedIcon: String?
        private let title: String
        private let onSelect: () -> Void

        private var labelIconName: String {
            isSelected ? selectedIcon ?? icon : icon
        }

        // MARK: - Body

        var body: some View {
            Group {
                if Content.self == EmptyView.self {
                    Button(action: onSelect) {
                        labelView
                    }
                    .buttonStyle(.card)
                } else {
                    Menu(content: content) {
                        labelView
                    }
                    .scaleEffect(isFocused ? 1.2 : 1.0)
                    .animation(
                        .spring(response: 0.2, dampingFraction: 1), value: isFocused
                    )
                    .buttonStyle(.plain)
                    .menuStyle(.borderlessButton)
                    .focused($isFocused)
                }
            }
            .focused($isFocused)
        }

        // MARK: - Label Views

        private var labelView: some View {
            ZStack {
                let isButton = Content.self == EmptyView.self

                if isButton, isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isFocused ? AnyShapeStyle(HierarchicalShapeStyle.primary) :
                                AnyShapeStyle(HierarchicalShapeStyle.primary.opacity(0.5))
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFocused ? Color.white : Color.white.opacity(0.5))
                }

                Label(title, systemImage: labelIconName)
                    .focusEffectDisabled()
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .labelStyle(.iconOnly)
                    .rotationEffect(isCompact ? .degrees(90) : .degrees(0))
            }
            .accessibilityLabel(title)
        }
    }
}

// MARK: - Initializers

extension ItemView.ActionButton {

    // MARK: Button Initializer

    init(
        _ title: String,
        icon: String,
        selectedIcon: String,
        onSelect: @escaping () -> Void
    ) where Content == EmptyView {
        self.title = title
        self.icon = icon
        self.isCompact = false
        self.selectedIcon = selectedIcon
        self.onSelect = onSelect
        self.content = { EmptyView() }
    }

    // MARK: Menu Initializer

    init(
        _ title: String,
        icon: String,
        isCompact: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isCompact = isCompact
        self.selectedIcon = nil
        self.onSelect = {}
        self.content = content
    }
}
