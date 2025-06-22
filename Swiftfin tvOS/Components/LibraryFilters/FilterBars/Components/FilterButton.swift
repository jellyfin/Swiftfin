//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct FilterButton: View {

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

    private let minWidth: CGFloat
    private let maxWidth: CGFloat

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
        minWidth: CGFloat,
        maxWidth: CGFloat,
        role: ButtonRole?,
        onSelect: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.title = title
        self.minWidth = minWidth
        self.maxWidth = maxWidth
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
                .frame(width: isFocused ? maxWidth : minWidth, height: minWidth)
                .overlay {
                    Capsule()
                        .stroke(buttonColor, lineWidth: 1)
                        .brightness(isFocused ? 0.25 : 0)
                }
                .allowsHitTesting(false)
                .position(x: (isFocused ? maxWidth : minWidth) / 2, y: minWidth / 2)
                .frame(width: isFocused ? maxWidth : minWidth, alignment: .leading)

            HStack(spacing: 10) {
                if let systemName = systemName {
                    Image(systemName: systemName)
                        .hoverEffectDisabled()
                        .focusEffectDisabled()
                        .foregroundColor(textColor)
                        .frame(width: minWidth, alignment: .center)
                }

                if isFocused {
                    Text(title)
                        .foregroundColor(textColor)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    Spacer(minLength: 10)
                }
            }
            .font(.footnote.weight(.semibold))
            .frame(height: minWidth)
            .allowsHitTesting(false)

            Button {
                onSelect()
            } label: {
                Color.clear
                    .frame(width: isFocused ? maxWidth : minWidth, height: minWidth)
            }
            .buttonStyle(.borderless)
            .focused($isFocused)
        }
        .frame(width: isFocused ? maxWidth : minWidth, height: minWidth, alignment: .leading)
        .animation(.easeIn(duration: 0.2), value: isFocused)
    }
}

extension FilterButton {
    init(
        systemName: String,
        title: String,
        minWidth: CGFloat = 70,
        maxWidth: CGFloat,
        role: ButtonRole? = nil
    ) {
        self.init(
            systemName: systemName,
            title: title,
            minWidth: minWidth,
            maxWidth: maxWidth,
            role: role,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
