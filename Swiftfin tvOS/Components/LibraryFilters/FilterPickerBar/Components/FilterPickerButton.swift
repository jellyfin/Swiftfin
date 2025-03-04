//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension FilterPickerBar {

    struct FilterPickerButton: View {

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
        private let role: ButtonRole?
        private var onSelect: () -> Void

        // MARK: - Button Dimensions

        private let collapsedWidth: CGFloat = 70

        private var expandedWidth: CGFloat {
            title.width(font: .footnote, weight: .semibold) + 30 + collapsedWidth
        }

        // MARK: - Button Styles

        private var buttonColor: Color {
            isSelected ? ((role == .destructive && isFocused) ? Color.red.opacity(0.2) : accentColor) : Color.secondarySystemFill
        }

        private var textColor: Color {
            isFocused ? ((role == .destructive) ? .red : .black) : .primary
        }

        // MARK: - Initializer

        init(
            systemName: String?,
            title: String,
            role: ButtonRole?,
            onSelect: @escaping () -> Void
        ) {
            self.systemName = systemName
            self.title = title
            self.role = role
            self.onSelect = onSelect
        }

        // MARK: - Body

        var body: some View {
            ZStack(alignment: .leading) {
                Capsule()
                    .foregroundColor(buttonColor)
                    .brightness(isFocused ? 0.25 : 0)
                    .opacity(isFocused ? 1 : 0.5)
                    .frame(width: isFocused ? expandedWidth : collapsedWidth, height: collapsedWidth)
                    .overlay {
                        Capsule()
                            .stroke(buttonColor, lineWidth: 1)
                            .brightness(isFocused ? 0.25 : 0)
                    }
                    .allowsHitTesting(false)

                HStack(spacing: 10) {
                    if let systemName = systemName {
                        Image(systemName: systemName)
                            .hoverEffectDisabled()
                            .focusEffectDisabled()
                            .foregroundColor(textColor)
                            .frame(width: collapsedWidth, alignment: .center)
                    }

                    if isFocused {
                        Text(title)
                            .foregroundColor(textColor)
                            .transition(.move(edge: .leading).combined(with: .opacity))

                        Spacer(minLength: 10)
                    }
                }
                .font(.footnote.weight(.semibold))
                .frame(height: collapsedWidth)
                .allowsHitTesting(false)

                Button {
                    onSelect()
                } label: {
                    Color.clear
                        .frame(width: collapsedWidth, height: collapsedWidth)
                }
                .padding(0)
                .buttonStyle(.borderless)
                .focused($isFocused)
            }
            .frame(width: collapsedWidth, height: collapsedWidth, alignment: .leading)
            .animation(.easeIn(duration: 0.2), value: isFocused)
        }
    }
}

extension FilterPickerBar.FilterPickerButton {
    init(systemName: String, title: String, role: ButtonRole? = nil) {
        self.init(
            systemName: systemName,
            title: title,
            role: role,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
