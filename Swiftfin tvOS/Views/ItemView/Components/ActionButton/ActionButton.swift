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

        // MARK: - Required Configuration

        private let icon: String
        private let title: String

        // MARK: - Button Configuration

        private let onSelect: () -> Void
        private let selectedIcon: String?

        // MARK: - Menu Configuration

        private let content: () -> Content
        private let isCompact: Bool

        // MARK: - Label Icon

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
                    .menuStyle(.borderlessButton)
                }
            }
            .focused($isFocused)
        }

        // MARK: - Label Views

        private var labelView: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(isSelected ? .secondary : .tertiary)
                    .opacity(isFocused ? 1.0 : 0.5)

                Label(title, systemImage: labelIconName)
                    .focusEffectDisabled()
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.monochrome)
                    .labelStyle(.iconOnly)
                    .rotationEffect(isCompact ? .degrees(90) : .degrees(0))
            }
            .accessibilityLabel(title)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
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
