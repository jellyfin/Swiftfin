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

        private let content: () -> Content
        private let icon: String
        private let onSelect: () -> Void
        private let selectedIcon: String?
        private let title: String
        private let buttonColor: Color?

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
                    .buttonStyle(.borderless)
                } else {
                    Menu(content: content) {
                        labelView
                    }
                    .menuStyle(.borderlessButton)
                }
            }
            .animation(.easeInOut(duration: 0.1), value: isSelected)
        }

        // MARK: - Label Views

        private var labelView: some View {
            ZStack {
                // Background shape
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(backgroundFill)

                // Icon
                Image(systemName: labelIconName)
                    .foregroundStyle(Color.accentColor.overlayColor)
            }
            .accessibilityLabel(title)
        }

        // MARK: - Background Fill

        private var backgroundFill: Color {
            if isSelected, let buttonColor {
                return buttonColor
            } else {
                return Color.secondary
            }
        }
    }
}

// MARK: - Initializers

extension ItemView.ActionButton {

    // MARK: Button Initializer

    init(
        _ title: String,
        icon: String,
        selectedIcon: String? = nil,
        buttonColor: Color? = nil,
        onSelect: @escaping () -> Void
    ) where Content == EmptyView {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.buttonColor = buttonColor
        self.onSelect = onSelect
        self.content = { EmptyView() }
    }

    // MARK: Menu Initializer

    init(
        _ title: String,
        icon: String,
        buttonColor: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.selectedIcon = nil
        self.buttonColor = buttonColor
        self.onSelect = {}
        self.content = content
    }
}
