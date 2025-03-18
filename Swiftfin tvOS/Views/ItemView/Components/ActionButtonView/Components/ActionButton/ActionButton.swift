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

        // MARK: - Mode

        private enum Mode {
            case button
            case menu
        }

        // MARK: - Environment Objects

        @Environment(\.isSelected)
        private var isSelected

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        // MARK: - Required Properties

        private let mode: Mode
        private let title: String
        private let icon: String

        // MARK: - Button Properties

        private let selectedIcon: String?
        private let onSelect: (() -> Void)?

        // MARK: - Menu Properties

        private let content: (() -> Content)?

        // MARK: - Body

        var body: some View {
            Group {
                switch mode {
                case .button:
                    Button(action: onSelect!) {
                        labelView
                    }
                case .menu:
                    Menu {
                        content?()
                    } label: {
                        labelView
                    }
                }
            }
            .focused($isFocused)
            .buttonStyle(ActionButtonStyle())
        }

        // MARK: - Label Views

        private var labelView: some View {
            ZStack {
                if mode == .button && isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isFocused ? AnyShapeStyle(HierarchicalShapeStyle.primary) :
                                AnyShapeStyle(HierarchicalShapeStyle.primary.opacity(0.5))
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFocused ? Color.white : Color.white.opacity(0.5))
                }

                Label(title, systemImage: (mode == .button && isSelected) ? (selectedIcon ?? icon) : icon)
                    .hoverEffectDisabled()
                    .focusEffectDisabled()
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .labelStyle(.iconOnly)
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
        self.mode = .button
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.onSelect = onSelect
        self.content = nil
    }

    // MARK: Menu Initializer

    init(
        _ title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.mode = .menu
        self.title = title
        self.icon = icon
        self.selectedIcon = nil
        self.onSelect = nil
        self.content = content
    }
}
