//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension LeadingBarFilterDrawer {

    struct FilterDrawerButton: View {

        // MARK: - Defaults

        @Default(.accentColor)
        private var accentColor

        // MARK: - Environment Variables

        @Environment(\.isSelected)
        private var isSelected

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        // MARK: - Button Variables

        private let systemName: String?
        private let title: String
        private var onSelect: () -> Void

        // MARK: - Collapsing Variables

        private let expandedWidth: CGFloat
        private let collapsedWidth: CGFloat = 75

        // MARK: - Initializer

        init(systemName: String?, title: String, expandedWidth: CGFloat, onSelect: @escaping () -> Void) {
            self.systemName = systemName
            self.title = title
            self.expandedWidth = expandedWidth
            self.onSelect = onSelect
        }

        // MARK: - Body

        var body: some View {
            Button {
                onSelect()
            } label: {
                HStack(spacing: 8) {
                    if let systemName = systemName {
                        Image(systemName: systemName)
                            .frame(width: collapsedWidth, alignment: .center)
                            .focusable(false)
                    }
                    if isFocused {
                        Text(title)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        Spacer(minLength: 0)
                    }
                }
                .font(.footnote.weight(.semibold))
                .foregroundColor(isFocused ? .primary : .secondary)
                .frame(
                    width: isFocused ? expandedWidth : collapsedWidth,
                    height: collapsedWidth,
                    alignment: .leading
                )
                .background {
                    Capsule()
                        .foregroundColor(isSelected ? accentColor : Color.secondarySystemFill)
                        .brightness(isFocused ? 0.25 : 0)
                        .opacity(0.5)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? accentColor : Color.secondarySystemFill, lineWidth: 1)
                        .brightness(isFocused ? 0.25 : 0)
                }
                .animation(.easeInOut(duration: 0.25), value: isFocused)
            }
            .frame(width: collapsedWidth, height: collapsedWidth, alignment: .leading)
            .buttonStyle(.borderless)
            .focused($isFocused)
        }
    }
}

extension LeadingBarFilterDrawer.FilterDrawerButton {

    init(systemName: String, title: String) {
        self.init(
            systemName: systemName,
            title: title,
            expandedWidth: 200,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
