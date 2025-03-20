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

        // MARK: - State

        @Environment(\.isSelected)
        private var isSelected

        // MARK: - Required Properties

        private let mode: Mode
        private let title: String
        private let icon: String
        private let selectedIcon: String
        private let color: Color
        private let multicolor: Bool

        // MARK: - Button Properties

        private let onSelect: (() -> Void)?

        // MARK: - Menu Properties

        private let content: (() -> Content)?

        // MARK: - Body

        var body: some View {
            Group {
                switch mode {
                case .button:
                    Button(action: {
                        onSelect?()
                    }) {
                        labelView
                    }
                    .buttonStyle(PlainButtonStyle())
                case .menu:
                    Menu {
                        content?()
                    } label: {
                        labelView
                    }
                }
            }
        }

        // MARK: - Label Views

        private var labelView: some View {
            Label(title, systemImage: isSelected ? selectedIcon : icon)
                .if(isSelected && multicolor) { button in
                    button
                        .foregroundStyle(
                            .primary,
                            color
                        )
                }
                .if(isSelected && !multicolor) { button in
                    button
                        .foregroundStyle(
                            color
                        )
                }
                .symbolRenderingMode(.palette)
                .labelStyle(.iconOnly)
                .animation(.easeInOut(duration: 0.1), value: isSelected)
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
        color: Color = .primary,
        multicolor: Bool = false,
        onSelect: @escaping () -> Void
    ) where Content == EmptyView {
        self.mode = .button
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.color = color
        self.multicolor = multicolor
        self.onSelect = onSelect
        self.content = nil
    }

    // MARK: Menu Initializer

    init(
        _ title: String,
        icon: String,
        color: Color = .primary,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.mode = .menu
        self.title = title
        self.icon = icon
        self.selectedIcon = icon
        self.color = color
        self.multicolor = false
        self.onSelect = nil
        self.content = content
    }
}
