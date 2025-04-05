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

        @Environment(\.isSelected)
        private var isSelected

        private let content: () -> Content
        private let icon: String
        private let onSelect: () -> Void
        private let selectedIcon: String?
        private let title: String

        private var labelIconName: String {
            isSelected ? selectedIcon ?? icon : icon
        }

        // MARK: - Body

        var body: some View {
            Group {
                if Content.self == EmptyView.self {
                    Button(
                        title,
                        systemImage: labelIconName,
                        action: onSelect
                    )
                    .buttonStyle(.plain)
                } else {
                    Menu(
                        title,
                        systemImage: labelIconName,
                        content: content
                    )
                }
            }
            .symbolRenderingMode(.palette)
            .labelStyle(.iconOnly)
            .animation(.easeInOut(duration: 0.1), value: isSelected)
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
        onSelect: @escaping () -> Void
    ) where Content == EmptyView {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.onSelect = onSelect
        self.content = { EmptyView() }
    }

    // MARK: Menu Initializer

    init(
        _ title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.selectedIcon = icon
        self.onSelect = {}
        self.content = content
    }
}
